import Foundation

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    func refreshAllAccounts() {
        let accounts = AccountStorage.shared.connectedAccounts()
        for acc in accounts {
            let provider = acc.provider?.lowercased() ?? ""
            let email = acc.email?.lowercased()
            switch provider {
            case "google":
                refreshGoogleAccount(emailHint: email)
            case "outlook":
                // TODO: Outlook path
                break
            default:
                break
            }
        }
    }

    private func refreshGoogleAccount(emailHint: String?) {
        let now = Date()
        let safetyFrom = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let safetyTo   = Calendar.current.date(byAdding: .day, value: 180, to: now)!

        if let email = emailHint,
           GoogleAccountStore.shared.syncToken(for: email) != nil {

            // 1) Delta
            GoogleAuthService.shared.deltaSync { emailFromSvc, items, deletedIDs in
                let accountEmail = emailFromSvc.lowercased()
                EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                EventStorage.shared.deleteExternalIDs(deletedIDs, accountEmail: accountEmail, provider: "google")
            } onComplete: { _, _ in
                // 2) Safety window
                GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc, items in
                    let accountEmail = emailFromSvc.lowercased()
                    EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                }
            }
            return
        }

        // No token -> backfill then seed, then safety window
        GoogleAuthService.shared.fetchLastThreeMonths { emailFromSvc, items in
            let accountEmail = emailFromSvc.lowercased()
            EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items)
        } onComplete: { _, _ in
            GoogleAuthService.shared.fetchRestOfYear { emailFromSvc2, items2 in
                let accountEmail = emailFromSvc2.lowercased()
                EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items2)
            } onComplete: { _, _ in
                GoogleAuthService.shared.seedSyncToken { email, ok in
                    if ok {
                        print("✅ Sync token saved for \(email)")
                    } else {
                        print("⚠️ Failed to seed sync token for \(email)")
                    }
                }
            }
        }
    }
}

