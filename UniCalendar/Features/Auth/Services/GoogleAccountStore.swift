import Foundation

/// Simple UserDefaults-backed store for Google Calendar `nextSyncToken` per account email.
/// Keys are always lowercased emails.
final class GoogleAccountStore {
    static let shared = GoogleAccountStore()
    private init() {}

    private let key = "google_sync_tokens"

    private var dict: [String: String] {
        get { (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func syncToken(for email: String) -> String? {
        dict[email.lowercased()]
    }

    func saveSyncToken(_ token: String, for email: String) {
        var d = dict
        d[email.lowercased()] = token
        dict = d
    }

    func removeSyncToken(for email: String) {
        var d = dict
        d.removeValue(forKey: email.lowercased())
        dict = d
    }

    func removeAll() {
        UserDefaults.standard.removeObject(forKey: key)
        print("🧹 Cleared all Google sync tokens")
    }
}

