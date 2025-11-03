import Foundation

// MARK: - Google Calendar API Models

struct GoogleCalendarResponse: Decodable {
    let items: [GoogleEvent]
    let nextPageToken: String?
    let nextSyncToken: String?
}

struct GoogleEvent: Decodable {
    struct When: Decodable {
        let dateTime: String?
        let date: String?
        let timeZone: String?
    }

    struct Attendee: Decodable {
        let email: String?
        let displayName: String?
        /// "accepted" | "declined" | "tentative" | "needsAction"
        let responseStatus: String?
        let organizer: Bool?
        let `self`: Bool?

        private enum CodingKeys: String, CodingKey {
            case email, displayName, responseStatus, organizer
            case `self` = "self"
        }
    }

    let id: String
    let status: String?
    let summary: String?
    let description: String?        // <-- agenda/notes
    let location: String?
    let start: When
    let end: When
    let attendees: [Attendee]?      // <-- attendees list
    let organizer: Organizer?
    let htmlLink: String?

    struct Organizer: Decodable {
        let email: String?
        let displayName: String?
    }
}

// MARK: - Optional: Unified app models (keep or remove if you already have these)

enum EventSource {
    case google
}
