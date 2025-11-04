import Foundation
import UserNotifications

enum NotificationPrefs {
    private static let enabledKey      = "unicalendar.notifications.enabled"
    private static let leadMinutesKey  = "unicalendar.notifications.leadMinutes"
    private static let soundOnKey      = "unicalendar.notifications.soundOn"
    private static let vibrateOnKey    = "unicalendar.notifications.vibrateOn"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var leadMinutes: Int {
        get { UserDefaults.standard.object(forKey: leadMinutesKey) as? Int ?? 15 }
        set { UserDefaults.standard.set(newValue, forKey: leadMinutesKey) }
    }

    static var soundOn: Bool {
        get { UserDefaults.standard.object(forKey: soundOnKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: soundOnKey) }
    }
    static var vibrateOn: Bool {
        get { UserDefaults.standard.object(forKey: vibrateOnKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: vibrateOnKey) }
    }

    static func setEnabled(_ on: Bool) {
        isEnabled = on
        if on {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}
