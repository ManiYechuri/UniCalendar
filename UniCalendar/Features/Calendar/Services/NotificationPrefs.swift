import Foundation

enum NotificationPrefs {
    private static let enabledKey = "notif_enabled"
    private static let leadKey = "notif_lead_minutes"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var leadMinutes: Int {
        get { UserDefaults.standard.object(forKey: leadKey) as? Int ?? 15 }
        set { UserDefaults.standard.set(newValue, forKey: leadKey) }
    }
}

