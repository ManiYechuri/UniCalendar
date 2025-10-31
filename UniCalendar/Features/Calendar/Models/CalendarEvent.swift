import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let location: String?
    let start: Date
    let end: Date
    let color: EventColor
    let source: Source
    
    enum EventColor {
        case blue, red
    }
    enum Source { case google, outlook }
}



