import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let location: String?
    let start: Date
    let end: Date
    let color: EventColor
    let source: Source

    let agenda: String?
    let attendees: [EventAttendee]?
    let htmlLink: String?

    enum EventColor {
        case blue, red
    }

    enum Source {
        case google, outlook
    }
}

// MARK: - Supporting model for attendees
struct EventAttendee: Equatable, Codable {
    let email: String?
    let name: String?
    let status: String? // e.g., "accepted", "declined", "tentative", "needsAction"
}

// Convert Google attendees -> EventAttendee
extension Array where Element == GoogleEvent.Attendee {
    func toEventAttendees() -> [EventAttendee] {
        map { .init(email: $0.email, name: $0.displayName, status: $0.responseStatus) }
    }
}

// Serialize/deserialize for Core Data Binary Data
enum AttendeesCodec {
    static func encode(_ attendees: [EventAttendee]?) -> Data? {
        guard let attendees else { return nil }
        return try? JSONEncoder().encode(attendees)
    }
    static func decode(_ data: Data?) -> [EventAttendee]? {
        guard let data else { return nil }
        return try? JSONDecoder().decode([EventAttendee].self, from: data)
    }
}


