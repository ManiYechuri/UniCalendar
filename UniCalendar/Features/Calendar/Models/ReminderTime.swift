import Foundation

enum ReminderTime: CaseIterable {
    case atEvent, min5, min15, min30, hour1, custom

    var label: String {
        switch self {
        case .atEvent: return "At time of event"
        case .min5:    return "5 minutes before"
        case .min15:   return "15 minutes before"
        case .min30:   return "30 minutes before"
        case .hour1:   return "1 hour before"
        case .custom:  return "Custom..."
        }
    }

    var minutesBefore: Int? {
        switch self {
        case .atEvent: return 0
        case .min5:    return 5
        case .min15:   return 15
        case .min30:   return 30
        case .hour1:   return 60
        case .custom:  return 15 
        }
    }

    static func fromStored(minutes: Int) -> ReminderTime {
        switch minutes {
        case 0:  return .atEvent
        case 5:  return .min5
        case 15: return .min15
        case 30: return .min30
        case 60: return .hour1
        default: return .min15
        }
    }
}

