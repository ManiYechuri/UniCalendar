import Foundation

enum ReminderTime: CaseIterable, Equatable {
    case atTime, min5, min10, min15, min30, hr1, hr2, day1

    var label: String {
        switch self {
        case .atTime: return "At time of event"
        case .min5:   return "5 minutes before"
        case .min10:  return "10 minutes before"
        case .min15:  return "15 minutes before"
        case .min30:  return "30 minutes before"
        case .hr1:    return "1 hour before"
        case .hr2:    return "2 hours before"
        case .day1:   return "1 day before"
        }
    }

    /// Minutes before start; 0 = at time.
    var minutesBefore: Int? {
        switch self {
        case .atTime: return 0
        case .min5:   return 5
        case .min10:  return 10
        case .min15:  return 15
        case .min30:  return 30
        case .hr1:    return 60
        case .hr2:    return 120
        case .day1:   return 24 * 60
        }
    }

    static var allCases: [ReminderTime] {
        [.atTime, .min5, .min10, .min15, .min30, .hr1, .hr2, .day1]
    }

    static func fromStored(minutes: Int) -> ReminderTime {
        switch minutes {
        case ..<1:     return .atTime
        case 5:        return .min5
        case 10:       return .min10
        case 15:       return .min15
        case 30:       return .min30
        case 60:       return .hr1
        case 120:      return .hr2
        case 1440:     return .day1
        default:       return .min15
        }
    }
}

