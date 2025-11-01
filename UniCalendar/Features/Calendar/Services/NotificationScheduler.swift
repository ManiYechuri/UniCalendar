import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    print(granted ? "🔔 Notifications granted" : "🔕 Denied")
                }
        }
    }

    func rescheduleAllUpcoming(daysAhead: Int = 180) {
        guard NotificationPrefs.isEnabled else {
            cancelAllScheduled()
            return
        }

        cancelAllScheduled()

        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!
        let events = EventStorage.shared.fetch(in: DateInterval(start: now, end: end))
        schedule(events: events, leadMinutes: NotificationPrefs.leadMinutes)
    }

    func schedule(events: [CalendarEvent], leadMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        for event in events {
            if event.end <= Date() { continue }

            // lead notification
            if let leadDate = Calendar.current.date(byAdding: .minute, value: -leadMinutes, to: event.start),
               leadDate > Date() {
                let id = makeIdentifier(for: event, suffix: "lead-\(leadMinutes)")
                let content = makeContent(
                    title: event.title,
                    body: "Starts at \(timeString(event.start))",
                    source: event.source
                )
                let trigger = makeCalendarTrigger(for: leadDate)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }

            // start notification
            if event.start > Date() {
                let id = makeIdentifier(for: event, suffix: "start")
                let content = makeContent(title: event.title, body: "Starting now", source: event.source)
                let trigger = makeCalendarTrigger(for: event.start)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    func cancelAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancel(for event: CalendarEvent) {
        let base = baseKey(for: event)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [
                "\(base)-start",
                "\(base)-lead-\(NotificationPrefs.leadMinutes)"
            ])
    }

    private func makeIdentifier(for event: CalendarEvent, suffix: String) -> String {
        "\(baseKey(for: event))-\(suffix)"
    }

    private func baseKey(for event: CalendarEvent) -> String {
        let ts = Int(event.start.timeIntervalSince1970)
        return "evt-\(ts)-\(event.title.hashValue)"
    }

    private func makeContent(title: String, body: String, source: CalendarEvent.Source) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["source": (source == .google ? "google" : "outlook")]
        return content
    }

    private func makeCalendarTrigger(for date: Date) -> UNCalendarNotificationTrigger {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: d)
    }
}

