import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    // MARK: UI config
    let rowHeight: CGFloat = 64
    let hoursRange = 0...23

    // MARK: Filters
    enum SourceFilter: CaseIterable {
        case all, google, outlook
    }

    @Published var sourceFilter: SourceFilter = .all

    // MARK: Selection
    @Published var selectedDate: Date = Date().startOfDayApp
    @Published private(set) var dayEvents: [CalendarEvent] = []

    private var bag = Set<AnyCancellable>()

    init() {
        // First load for today
        reloadForSelectedDay()

        // Reload when Core Data posts updates
        NotificationCenter.default.publisher(for: .eventsDidUpdate)
            .sink { [weak self] _ in self?.reloadForSelectedDay() }
            .store(in: &bag)

        // If the filter changes, re-query
        $sourceFilter
            .dropFirst()
            .sink { [weak self] _ in self?.reloadForSelectedDay() }
            .store(in: &bag)
    }

    // MARK: Header helpers

    var titleString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }

    func daysInWeek() -> [Date] {
        let cal = Calendar.app
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    func select(date: Date) {
        guard !date.isSameDay(as: selectedDate) else { return }
        selectedDate = date.startOfDayApp
        reloadForSelectedDay()
    }

    func goToPreviousWeek() {
        selectedDate = Calendar.app.date(byAdding: .day, value: -7, to: selectedDate)!.startOfDayApp
        reloadForSelectedDay()
    }

    func goToNextWeek() {
        selectedDate = Calendar.app.date(byAdding: .day, value: 7, to: selectedDate)!.startOfDayApp
        reloadForSelectedDay()
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

        // Fetch from storage (you likely already have this API)
        var events = EventStorage.shared.fetch(in: window, accounts: nil)

        // Keep only events that overlap the selected day (protects cross-midnight events)
        events = events.filter { ev in
            DateInterval(start: ev.start, end: ev.end).intersects(window)
        }

        // Apply source filter
        switch sourceFilter {
        case .all:
            break
        case .google:
            events = events.filter { $0.source == .google }
        case .outlook:
            events = events.filter { $0.source == .outlook }
        }

        dayEvents = events.sorted { $0.start < $1.start }
    }
}

