import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    let rowHeight: CGFloat = 64
    let hoursRange = 0...23

    enum SourceFilter: CaseIterable { case all, google, outlook }
    @Published var sourceFilter: SourceFilter = .all

    @Published var selectedDate: Date = Date().startOfDayApp
    @Published private(set) var visibleWeekAnchor: Date = Date()

    @Published private(set) var dayEvents: [CalendarEvent] = []

    private var bag = Set<AnyCancellable>()

    init() {
        visibleWeekAnchor = Date()
        reloadForSelectedDay()
        NotificationCenter.default.publisher(for: .eventsDidUpdate)
            .sink { [weak self] _ in self?.reloadForSelectedDay() }
            .store(in: &bag)

        $sourceFilter
            .dropFirst()
            .sink { [weak self] _ in self?.reloadForSelectedDay() }
            .store(in: &bag)
    }

    // MARK: Header helpers
    var titleString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: visibleWeekAnchor)
    }

    func daysInWeek() -> [Date] {
        let cal = Calendar.app
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: visibleWeekAnchor))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    func select(date: Date) {
        let normalized = date.startOfDayApp
        guard !normalized.isSameDay(as: selectedDate) else { return }
        selectedDate = normalized
        visibleWeekAnchor = normalized
        reloadForSelectedDay()
    }

    func goToPreviousWeek() {
        visibleWeekAnchor = Calendar.app.date(byAdding: .day, value: -7, to: visibleWeekAnchor) ?? visibleWeekAnchor
    }

    func goToNextWeek() {
        visibleWeekAnchor = Calendar.app.date(byAdding: .day, value: 7, to: visibleWeekAnchor) ?? visibleWeekAnchor
    }

    // MARK: Day-scoped events

    func eventsForSelectedDay(hour: Int) -> [CalendarEvent] {
        dayEvents.filter { event in
            Calendar.app.component(.hour, from: event.start) == hour
        }
    }

    func reloadForSelectedDay() {
        let cal = Calendar.app
        let start = selectedDate.startOfDayApp
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let window = DateInterval(start: start, end: end)

        var events = EventStorage.shared.fetch(in: window, accounts: nil)

        events = events.filter { ev in
            DateInterval(start: ev.start, end: ev.end).intersects(window)
        }

        switch sourceFilter {
        case .all: break
        case .google: events = events.filter { $0.source == .google }
        case .outlook: events = events.filter { $0.source == .outlook }
        }

        dayEvents = events.sorted { $0.start < $1.start }
    }
}

