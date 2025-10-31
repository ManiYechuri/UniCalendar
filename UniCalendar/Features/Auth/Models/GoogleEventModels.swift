import Foundation

// MARK: - Google API models

struct GoogleCalendarResponse: Decodable {
    let items: [GoogleEvent]
    let nextPageToken: String?
    let nextSyncToken: String?
}

struct GoogleEvent: Decodable {
    struct When: Decodable {
        let dateTime: String?
        let date: String?
    }
    let id: String
    let status: String?
    let summary: String?
    let location: String?
    let start: When
    let end: When
}
