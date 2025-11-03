// SyncManager.swift (replace the whole file or merge carefully)
import Foundation

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    func refreshAllAccounts() {
        let accounts = AccountStorage.shared.connectedAccounts()
        let googleAccounts = accounts.filter { ($0.provider ?? "").lowercased() == "google" }

        guard !googleAccounts.isEmpty else {
            NotificationCenter.default.post(name: .syncDidFinish, object: nil)
            return
        }

        NotificationCenter.default.post(name: .syncWillStart, object: nil)

        var pending = googleAccounts.count
        for acc in googleAccounts {
            refreshGoogleAccount(emailHint: acc.email?.lowercased()) {
                pending -= 1
                if pending == 0 {
                    NotificationCenter.default.post(name: .syncDidFinish, object: nil)
                    // Optionally: one final UI refresh ping
                    NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
                }
            }
        }
    }
    
    func pullLatest(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .syncWillStart, object: nil)
        }
        
        GoogleAuthService.shared.deltaSync { email, items, deletedIDs in
            EventStorage.shared.upsertGoogleItems(accountEmail: email, items: items)
            EventStorage.shared.deleteExternalIDs(deletedIDs, accountEmail: email, provider: "google")
        } onComplete: { _, _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .syncDidFinish, object: nil)
            }
            completion()
        }
    }
    
    func initialBackfill(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        var lastEmail = ""
        
        group.enter()
        GoogleAuthService.shared.fetchLastThreeMonths { email, items in
            lastEmail = email
            EventStorage.shared.upsertGoogleItems(accountEmail: email, items: items)
        } onComplete: { _, _ in group.leave() }
        
        group.enter()
        GoogleAuthService.shared.fetchRestOfYear { email, items in
            lastEmail = email
            EventStorage.shared.upsertGoogleItems(accountEmail: email, items: items)
        } onComplete: { _, _ in group.leave() }
        
        group.notify(queue: .global()) {
            GoogleAuthService.shared.seedSyncToken { _, _ in
                completion()
            }
        }
    }

    private func refreshGoogleAccount(emailHint: String?, completion: @escaping () -> Void) {
        let now = Date()
        let safetyFrom = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let safetyTo   = Calendar.current.date(byAdding: .day, value: 180, to: now)!

        if let email = emailHint,
           GoogleAccountStore.shared.syncToken(for: email) != nil {

            GoogleAuthService.shared.deltaSync(
                onPage: { emailFromSvc, items, deletedIDs in
                    let accountEmail = emailFromSvc.lowercased()
                    EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                    EventStorage.shared.deleteExternalIDs(deletedIDs, accountEmail: accountEmail, provider: "google")
                },
                onComplete: { _, _ in
                    GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc, items in
                        let accountEmail = emailFromSvc.lowercased()
                        EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                    }
                    completion()
                }
            )
            return
        }

        GoogleAuthService.shared.fetchLastThreeMonths(
            onPage: { emailFromSvc, items in
                let accountEmail = emailFromSvc.lowercased()
                EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items)
            },
            onComplete: { _, _ in
                GoogleAuthService.shared.fetchRestOfYear(
                    onPage: { emailFromSvc2, items2 in
                        let accountEmail = emailFromSvc2.lowercased()
                        EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items2)
                    },
                    onComplete: { _, _ in
                        GoogleAuthService.shared.seedSyncToken { _, _ in
                            GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc3, items3 in
                                let accountEmail = emailFromSvc3.lowercased()
                                EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items3)
                            }
                            completion()
                        }
                    }
                )
            }
        )
    }
}

