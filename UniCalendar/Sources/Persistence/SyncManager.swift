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

    func refreshGoogleAccount(emailHint: String?) {
        let now = Date()
        // safety window to reconcile anything the delta may miss (recent past + near future)
        let safetyFrom = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let safetyTo   = Calendar.current.date(byAdding: .day, value: 180, to: now)!

        if let email = emailHint,
           GoogleAccountStore.shared.syncToken(for: email) != nil {

            // 1) Delta sync using nextSyncToken
            GoogleAuthService.shared.deltaSync { emailFromSvc, items, deletedIDs in
                let accountEmail = emailFromSvc.lowercased()
                EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                EventStorage.shared.deleteExternalIDs(deletedIDs, accountEmail: accountEmail, provider: "google")
            } onComplete: { _, _ in
                // 2) Safety-window pass (single completion closure)
                GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc, items in
                    let accountEmail = emailFromSvc.lowercased()
                    EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items)
                    // Let UI reload once at the end of the cycle
                    NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
                }
            }
            return
        }

        // No token → backfill (last 3 months, then rest of year), then seed token, then safety window
        GoogleAuthService.shared.fetchLastThreeMonths { emailFromSvc, items in
            let accountEmail = emailFromSvc.lowercased()
            EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items)
        } onComplete: { _, _ in
            GoogleAuthService.shared.fetchRestOfYear { emailFromSvc2, items2 in
                let accountEmail = emailFromSvc2.lowercased()
                EventStorage.shared.replaceGoogleEvents(accountEmail: accountEmail, items: items2)
            } onComplete: { _, _ in
                GoogleAuthService.shared.seedSyncToken { emailSeed, ok in
                    if !ok {
                        print("⚠️ Failed to seed sync token for \(emailSeed)")
                    }
                    // Safety-window pass even after fresh seed
                    GoogleAuthService.shared.fetchWindow(from: safetyFrom, to: safetyTo) { emailFromSvc3, items3 in
                        let accountEmail = emailFromSvc3.lowercased()
                        EventStorage.shared.upsertGoogleItems(accountEmail: accountEmail, items: items3)
                        NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
                    }
                }
            }
        }
    }
}

