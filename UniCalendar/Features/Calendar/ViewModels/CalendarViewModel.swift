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
        reloadForSelectedDay_async()
        NotificationCenter.default.publisher(for: .eventsDidUpdate)
            .sink { [weak self] _ in self?.reloadForSelectedDay_async() }
            .store(in: &bag)

        $sourceFilter
            .dropFirst()
            .sink { [weak self] _ in self?.reloadForSelectedDay_async() }
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
        reloadForSelectedDay_async()
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

    func reloadForSelectedDay_async(completion: (() -> Void)? = nil) {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: selectedDate)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let window = DateInterval(start: start, end: end)
        
        EventStorage.shared.fetchAsync(in: window, accounts: nil) { [weak self] events in
            guard let self else { return }
            var filtered = events
            switch self.sourceFilter {
            case .all: break
            case .google:  filtered = filtered.filter { $0.source == .google }
            case .outlook: filtered = filtered.filter { $0.source == .outlook }
            }
            self.dayEvents = filtered.sorted { $0.start < $1.start }
        }
        DispatchQueue.main.async { completion?() }
    }

}

