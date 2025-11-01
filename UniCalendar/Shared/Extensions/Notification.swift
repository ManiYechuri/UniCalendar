import Foundation

extension Notification.Name {
    static let eventsDidUpdate = Notification.Name("eventsDidUpdate")
    static let accountsDidChange = Notification.Name("accountsDidChange")
    static let syncWillStart = Notification.Name("syncWillStart")
    static let syncDidFinish = Notification.Name("syncDidFinish")
}
