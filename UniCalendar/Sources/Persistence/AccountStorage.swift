import CoreData
import Foundation


final class AccountStorage {
    static let shared = AccountStorage()
    private let context = PersistenceController.shared.container.viewContext
    private init() {}
    
    // MARK: - Fetch
    
    func connectedAccounts() -> [AccountEntity] {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        
        return (try? context.fetch(req)) ?? []
    }
    
    func account(byEmail email: String) -> AccountEntity? {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "email ==[c] %@", email)
        return try? context.fetch(req).first
    }
    
    // MARK: - Upsert / Remove
    @discardableResult
    func upsertAccount(email: String, provider: String, displayName: String? = nil) -> AccountEntity {
        let e = email.lowercased()
        let p = provider.lowercased()
        
        let obj = account(byEmail: e) ?? AccountEntity(context: context)
        obj.email = e
        obj.provider = p
        obj.displayName = displayName
        
        if obj.connectedAt == nil { obj.connectedAt = Date() }
        obj.isConnected = true
        obj.status = "connected"
        
        save()
        return obj
    }
    
        func removeAccount(email: String, deleteEvents: Bool = true) {
        let e = email.lowercased()
        if let obj = account(byEmail: e) {
            context.delete(obj)
            save()
        }
        
        GoogleAccountStore.shared.removeSyncToken(for: e)
            if deleteEvents {
            EventStorage.shared.deleteAllEvents(forAccountEmail: e)
        }
    }
    
    /// Nukes all accounts (useful for testing resets).
    func nukeAllAccounts(deleteEventsToo: Bool = false) {
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AccountEntity")
        let del = NSBatchDeleteRequest(fetchRequest: req)
        _ = try? context.execute(del)
        save()
        print("🧨 Deleted all AccountEntity rows")
        
        GoogleAccountStore.shared.removeAll()
        
        if deleteEventsToo {
            EventStorage.shared.nukeAll()
        }
    }
    
    // MARK: - Save
    
    private func save() {
        do { try context.save() }
        catch { print("Account save error:", error) }
    }
    
    func hasAnyConnectedAccount(onlyConnected: Bool = true) -> Bool {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        if onlyConnected {
            req.predicate = NSPredicate(format: "status == %@", "connected")
        }
        req.fetchLimit = 1
        do { return try context.count(for: req) > 0 }
        catch { print("Account count error:", error); return false }
    }
    
    func migrateAccountsSchemaIfNeeded() {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        if let rows = try? context.fetch(req) {
            var mutated = false
            for a in rows {
                if a.connectedAt == nil {
                    a.connectedAt = Date()
                    mutated = true
                }

                // If `isConnected` is optional, set default when missing
                if a.value(forKey: "isConnected") == nil {
                    a.setValue(true, forKey: "isConnected")
                    mutated = true
                }

                if a.status == nil {
                    a.status = "connected"
                    mutated = true
                }
            }

            if mutated { save() }
        }
    }

}

