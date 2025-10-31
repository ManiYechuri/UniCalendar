import CoreData
import Foundation

final class EventStorage {
    static let shared = EventStorage()

    private let container = PersistenceController.shared.container
    private var viewContext: NSManagedObjectContext { container.viewContext }
    private lazy var bgContext: NSManagedObjectContext = {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }()

    private init() {}

    // MARK: - GOOGLE SYNC APIS (what SyncManager calls)

    /// Full replace for a given account/provider (used in initial backfill windows)
    func replaceGoogleEvents(accountEmail: String, items: [GoogleEvent]) {
        let email = accountEmail.lowercased()
        bgContext.perform {
            // wipe existing google events for this account
            let fetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EventEntity")
            fetch.predicate = NSPredicate(format: "accountEmail == %@ AND source == %@", email, "google")
            let del = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? self.bgContext.execute(del)

            self.insert(googleItems: items, accountEmail: email, into: self.bgContext)
            self.saveAndNotify()
        }
    }

    /// Upsert items by externalID (used in delta and safety window)
    func upsertGoogleItems(accountEmail: String, items: [GoogleEvent]) {
        let email = accountEmail.lowercased()
        bgContext.perform {
            self.upsert(googleItems: items, accountEmail: email, into: self.bgContext)
            self.saveAndNotify()
        }
    }

    /// Delete by external IDs (used for cancelled items in delta)
    func deleteExternalIDs(_ ids: [String], accountEmail: String, provider: String) {
        guard !ids.isEmpty else { return }
        let email = accountEmail.lowercased()
        bgContext.perform {
            let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EventEntity")
            req.predicate = NSPredicate(
                format: "externalID IN %@ AND accountEmail == %@ AND source == %@",
                ids, email, provider.lowercased()
            )
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? self.bgContext.execute(del)
            self.saveAndNotify()
        }
    }

    // MARK: - Existing simple APIs (optional keep)

    func fetchAll() -> [CalendarEvent] {
        var result: [CalendarEvent] = []
        viewContext.performAndWait {
            let req: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            if let entities = try? viewContext.fetch(req) {
                result = self.mapToAppModel(entities)
            }
        }
        return result
    }

    func fetch(in range: DateInterval, accounts: [String]? = nil) -> [CalendarEvent] {
        var result: [CalendarEvent] = []
        viewContext.performAndWait {
            let req: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            var preds: [NSPredicate] = [
                NSPredicate(format: "start >= %@ AND start < %@", range.start as NSDate, range.end as NSDate)
            ]
            if let accounts, !accounts.isEmpty {
                let lowered = accounts.map { $0.lowercased() }
                preds.append(NSPredicate(format: "accountEmail IN %@", lowered))
            }
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
            if let entities = try? viewContext.fetch(req) {
                result = self.mapToAppModel(entities)
            }
        }
        return result
    }

    /// Delete all events for one account (used when disconnecting an account)
    func deleteAllEvents(forAccountEmail email: String) {
        let e = email.lowercased()
        viewContext.performAndWait {
            let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EventEntity")
            req.predicate = NSPredicate(format: "accountEmail == %@", e)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? viewContext.execute(del)
            try? viewContext.save()
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
        }
        print("🗑️ Deleted events for account \(e)")
    }

    /// Nuke everything (handy for testing when LoginView appears with no accounts)
    func nukeAll() {
        viewContext.performAndWait {
            let fetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EventEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? viewContext.execute(deleteRequest)
            try? viewContext.save()
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
        }
        print("🧨 Deleted all EventEntity rows")
    }

    // MARK: - Internals

    private func saveAndNotify() {
        do { try bgContext.save() } catch { print("CoreData save error:", error) }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
        }
    }

    private func insert(googleItems: [GoogleEvent], accountEmail: String, into ctx: NSManagedObjectContext) {
        let parse = makeDateParsers()
        for item in googleItems {
            if item.status == "cancelled" { continue }

            let e = EventEntity(context: ctx)
            e.id = UUID()
            e.externalID = item.id
            e.accountEmail = accountEmail
            e.source = "google"
            e.title = item.summary ?? "(No Title)"
            e.location = item.location

            let dates = parseGoogleDates(item, parse: parse)
            e.start = dates.start
            e.end   = dates.end
            e.color = "blue"
        }
    }

    private func upsert(googleItems: [GoogleEvent], accountEmail: String, into ctx: NSManagedObjectContext) {
        let parse = makeDateParsers()

        for item in googleItems {
            // deletes handled via deleteExternalIDs; skip cancelled creates
            if item.status == "cancelled" { continue }

            let req: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            req.fetchLimit = 1
            req.predicate = NSPredicate(
                format: "externalID == %@ AND accountEmail == %@ AND source == %@",
                item.id, accountEmail, "google"
            )
            let existing = (try? ctx.fetch(req))?.first
            let e = existing ?? EventEntity(context: ctx)
            if existing == nil { e.id = UUID() }

            e.externalID = item.id
            e.accountEmail = accountEmail
            e.source = "google"
            e.title = item.summary ?? "(No Title)"
            e.location = item.location

            let dates = parseGoogleDates(item, parse: parse)
            e.start = dates.start
            e.end   = dates.end
            e.color = "blue"
        }
    }

    private func mapToAppModel(_ entities: [EventEntity]) -> [CalendarEvent] {
        entities.compactMap { e in
            guard let start = e.start, let end = e.end else { return nil }
            return CalendarEvent(
                title: e.title ?? "(No Title)",
                location: e.location,
                start: start,
                end: end,
                color: (e.color == "red") ? .red : .blue,
                source: (e.source == "outlook") ? .outlook : .google
            )
        }
    }

    // MARK: - Date parsing helpers (handles dateTime and all-day date)

    private struct Parsers {
        let isoWithFrac: ISO8601DateFormatter
        let isoBasic: ISO8601DateFormatter
        let gmt: TimeZone
        let cal: Calendar
    }

    private func makeDateParsers() -> Parsers {
        let frac = ISO8601DateFormatter()
        frac.timeZone = TimeZone(secondsFromGMT: 0)
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let basic = ISO8601DateFormatter()
        basic.timeZone = TimeZone(secondsFromGMT: 0)
        basic.formatOptions = [.withInternetDateTime]

        return Parsers(
            isoWithFrac: frac,
            isoBasic: basic,
            gmt: TimeZone(secondsFromGMT: 0)!,
            cal: Calendar(identifier: .gregorian)
        )
    }

    private func parseGoogleDates(_ item: GoogleEvent, parse: Parsers) -> (start: Date?, end: Date?) {
        // If all-day: Google sends `date` (YYYY-MM-DD); treat as local all-day (start at 00:00, end next day 00:00)
        if let day = item.start.date ?? item.start.dateTime {
            if day.count == 10 { // "YYYY-MM-DD"
                let comps = day.split(separator: "-").compactMap { Int($0) }
                if comps.count == 3 {
                    var c = DateComponents()
                    c.year = comps[0]; c.month = comps[1]; c.day = comps[2]
                    c.hour = 0; c.minute = 0; c.second = 0
                    let start = parse.cal.date(from: c)
                    let end = parse.cal.date(byAdding: .day, value: 1, to: start ?? Date())
                    return (start, end)
                }
            }
        }

        let sRaw = item.start.dateTime ?? item.start.date
        let eRaw = item.end.dateTime   ?? item.end.date

        let s = parse.isoWithFrac.date(from: sRaw ?? "") ?? parse.isoBasic.date(from: sRaw ?? "")
        let e = parse.isoWithFrac.date(from: eRaw ?? "") ?? parse.isoBasic.date(from: eRaw ?? "")
        return (s, e)
    }
    
    func deleteAll(forAccountEmail email: String) {
        deleteAllEvents(forAccountEmail: email)
    }
}

private struct EventRowDTO {
    let title: String
    let location: String?
    let start: Date
    let end: Date
    let color: String
    let source: String
}

// MARK: - Async, non-blocking fetch for UI (use this in view models)
extension EventStorage {

    /// Background fetch with batching and a narrow property set.
    /// Calls `completion` on the main thread with mapped `CalendarEvent`s.
    func fetchAsync(in range: DateInterval,
                    accounts: [String]? = nil,
                    completion: @escaping ([CalendarEvent]) -> Void) {
        let lowered = accounts?.map { $0.lowercased() }

        bgContext.perform {
            let req = NSFetchRequest<NSManagedObject>(entityName: "EventEntity")

            var preds: [NSPredicate] = [
                NSPredicate(format: "start >= %@ AND start < %@", range.start as NSDate, range.end as NSDate)
            ]
            if let lowered, !lowered.isEmpty {
                preds.append(NSPredicate(format: "accountEmail IN %@", lowered))
            }
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)

            // Perf knobs
            req.fetchBatchSize = 200
            req.returnsObjectsAsFaults = true
            req.includesPropertyValues = true
            req.propertiesToFetch = ["title", "location", "start", "end", "color", "source"]
            req.resultType = .managedObjectResultType
            req.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]

            guard let rows = try? self.bgContext.fetch(req) else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Map to DTOs on background
            let dtos: [EventRowDTO] = rows.compactMap { obj in
                guard
                    let start = obj.value(forKey: "start") as? Date,
                    let end   = obj.value(forKey: "end")   as? Date
                else { return nil }
                return EventRowDTO(
                    title: (obj.value(forKey: "title") as? String) ?? "(No Title)",
                    location: obj.value(forKey: "location") as? String,
                    start: start,
                    end: end,
                    color: (obj.value(forKey: "color") as? String) ?? "blue",
                    source: (obj.value(forKey: "source") as? String) ?? "google"
                )
            }

            // Convert to app model
            let events: [CalendarEvent] = dtos.map {
                CalendarEvent(
                    title: $0.title,
                    location: $0.location,
                    start: $0.start,
                    end: $0.end,
                    color: ($0.color == "red") ? .red : .blue,
                    source: ($0.source == "outlook") ? .outlook : .google
                )
            }

            DispatchQueue.main.async { completion(events) }
        }
    }
}


