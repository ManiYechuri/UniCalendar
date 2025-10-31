import SwiftUI

enum CalendarProvider: String, Codable, CaseIterable {
    case google = "Google"
    case outlook = "Outlook"
    
    var icon: Image {
        switch self {
        case .google:  return Image(systemName: "g.circle.fill")
        case .outlook: return Image(systemName: "o.circle.fill")
        }
    }
    
    var tint: Color {
        switch self {
        case .google:  return .red
        case .outlook: return .blue
        }
    }
}

enum SyncStatus { case connected, syncing, error }

struct SyncAccount: Identifiable, Equatable {
    let id = UUID()
    let email: String
    let provider: CalendarProvider
    let status: SyncStatus
}

