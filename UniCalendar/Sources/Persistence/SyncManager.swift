// SyncManager.swift (replace the whole file or merge carefully)
import Foundation

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    func refreshAllAccounts() {
        let accounts = AccountStorage.shared.connectedAccounts()
        let googleAccounts = accounts.filter { ($0.provider ?? "").lowercased() == "google" }

        guard !googleAccounts.isEmpty else {
            // Nothing to refresh—tell UI to hide loader just in case
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

    private func refreshGoogleAccount(emailHint: String?, completion: @escaping () -> Void) {
        let now = Date()
        let safetyFrom = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let safetyTo   = Calendar.current.date(byAdding: .day, value: 180, to: now)!

        // If we have a sync token -> delta + safety window
        if let email = emailHint,
           GoogleAccountStore.shared.syncToken(for: email) != nil {

            GoogleAuthService.shared.deltaSync(
                onPage: { emailFromSvc, items, deletedIDs in
                    let accountEmail = emailFromSvc.lowercased()
                    EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                    EventStorage.shared.deleteExternalIDs(deletedIDs, accountEmail: accountEmail, provider: "google")
                },
                onComplete: { _, _ in
                    // Safety window (idempotent upsert)
                    GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc, items in
                        let accountEmail = emailFromSvc.lowercased()
                        EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                    }
                    completion()
                }
            )
            return
        }

        // First-time backfill -> seed token -> safety window
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
                            // Safety window anyway
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

