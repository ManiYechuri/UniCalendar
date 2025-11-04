import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus != .authorized else { return }
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }

    func rescheduleAllUpcoming() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard NotificationPrefs.isEnabled else { return }
        
        let now = Date()
        let futureLimit = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        let events = EventStorage.shared.fetch(in: DateInterval(start: now, end: futureLimit))
        
        let lead = NotificationPrefs.leadMinutes
        for ev in events {
            scheduleBothStartAndLead(event: ev, leadMinutes: lead)
        }
    }
    
    private func scheduleBothStartAndLead(event: CalendarEvent, leadMinutes: Int) {
        let now = Date()
        let atStart = event.start
        let atLead = Calendar.current.date(byAdding: .minute, value: -leadMinutes, to: event.start)
        
        var fireDates: [Date] = [atStart]
        if let atLead, leadMinutes > 0 { fireDates.append(atLead) }
        fireDates = Array(Set(fireDates)).sorted()
        
        for fire in fireDates where fire > now {
            scheduleNotification(for: event, fireDate: fire, isStartTime: fire == atStart)
        }
    }

    private func scheduleNotification(for event: CalendarEvent, fireDate: Date, isStartTime: Bool) {
        guard NotificationPrefs.isEnabled else { return }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        comps.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = event.title
        if let loc = event.location, !loc.isEmpty { content.subtitle = loc }
        if NotificationPrefs.soundOn { content.sound = .default }
        
        let kindSuffix: String = isStartTime ? "start" : "lead-\(NotificationPrefs.leadMinutes)"
        let identifier = "event-\(event.id.uuidString)-\(Int(event.start.timeIntervalSince1970))-\(kindSuffix)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { err in
            if let err { print("🔔 schedule error:", err.localizedDescription) }
        }
    }
}

