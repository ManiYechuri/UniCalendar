import SwiftUI

struct WeekCalendarView: View {
    @StateObject private var vm = CalendarViewModel()
    @State private var isLoading = false
    @State private var popupHour: Int?
    @State private var popupEvents: [CalendarEvent] = []
    @State private var showPopup = false
    @State private var selectedEvent: CalendarEvent? = nil

    @State private var showFilter = false
    @State private var pendingFilter: CalendarViewModel.SourceFilter = .all

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                WeekHeaderView(
                    monthTitle: vm.titleString,
                    days: vm.daysInWeek(),
                    selectedDate: vm.selectedDate,
                    onPrev: vm.goToPreviousWeek,
                    onNext: vm.goToNextWeek,
                    onSelect: vm.select(date:),
                    onSettings: {
                        pendingFilter = vm.sourceFilter
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFilter = true
                        }
                    }
                )

                Divider()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            ForEach(Array(vm.hoursRange), id: \.self) { hour in
                                HourRowView(
                                    hour: hour,
                                    events: vm.eventsForSelectedDay(hour: hour),
                                    onMoreTapped: { h, events in
                                        popupHour = h
                                        popupEvents = events
                                        withAnimation(.easeInOut(duration: 0.22)) { showPopup = true }
                                    },
                                    onEventTapped: { ev in
                                        selectedEvent = ev
                                    }
                                )
                                .frame(height: vm.rowHeight, alignment: .top)
                            }
                        }
                        .overlay(emptyStateView, alignment: .top)
                    }
                    .onAppear {
                        scrollToInitialHour(using: proxy)
                    }
                    .onChange(of: vm.selectedDate) { _ in
                        scrollToInitialHour(using: proxy)
                    }
                    .sheet(item: $selectedEvent) { ev in
                        NavigationView {
                            EventDetailView(event: ev)
                                .navigationBarTitle("", displayMode: .inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Close") { selectedEvent = nil }
                                    }
                                }
                        }
                    }
                }
            }
            .blur(radius: (showPopup || showFilter) ? 2 : 0)
            .zIndex(0)

            if showPopup || showFilter {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showFilter { withAnimation(.easeInOut(duration: 0.18)) { showFilter = false } }
                        if showPopup { dismissMorePopup() }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }

            if showPopup {
                MoreEventsPopupView(
                    title: popupTitle(),
                    events: hiddenEventsOnly(),
                    onClose: { dismissMorePopup() },
                    onSelect: { ev in
                        selectedEvent = ev        // open details
                        dismissMorePopup()        // close popup
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }

            if showFilter {
                VStack {
                    Spacer()
                    FilterPopupView(
                        selection: $pendingFilter,
                        onClose: { withAnimation(.easeInOut(duration: 0.18)) { showFilter = false } },
                        onApply: {
                            vm.sourceFilter = pendingFilter
                            withAnimation(.easeInOut(duration: 0.18)) { showFilter = false }
                        }
                    )
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }
            if isLoading {
                LoadingOverlay(text: "Syncing calendars…")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showFilter)
        .animation(.easeInOut(duration: 0.2), value: showPopup)
        .navigationBarHidden(true)
        .onAppear {
            if AccountStorage.shared.hasAnyConnectedAccount() {
                isLoading = true
            }
            vm.reloadForSelectedDay_async {
                isLoading = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncWillStart)) { _ in
            isLoading = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventsDidUpdate)) { _ in
            vm.reloadForSelectedDay_async()
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncDidFinish)) { _ in
            isLoading = false
        }
        .sheet(item: $selectedEvent) { ev in
            NavigationView {
                EventDetailView(event: ev)
                    .navigationBarTitle("", displayMode: .inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { selectedEvent = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Helpers

    private var emptyStateView: some View {
        let hasAny = vm.hoursRange.contains { !vm.eventsForSelectedDay(hour: $0).isEmpty }
        return Group {
            if !hasAny {
                Text("No events for this day")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
            }
        }
    }

    private func dismissMorePopup() {
        withAnimation(.easeInOut(duration: 0.18)) { showPopup = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            popupHour = nil
            popupEvents = []
        }
    }

    private func hiddenEventsOnly() -> [CalendarEvent] {
        Array(popupEvents.dropFirst(2))
    }

    private func popupTitle() -> String {
        if let firstHidden = hiddenEventsOnly().first {
            let f = DateFormatter(); f.timeStyle = .short
            return "Events at \(f.string(from: firstHidden.start))"
        }
        if let hour = popupHour {
            let p = hour < 12 ? "AM" : "PM"
            let h12 = hour % 12 == 0 ? 12 : hour % 12
            return "Events at \(h12):00 \(p)"
        }
        return "Events"
    }

    private func scrollToInitialHour(using proxy: ScrollViewProxy) {
        let cal = Calendar.app
        if cal.isDateInToday(vm.selectedDate) {
            proxy.scrollTo(Date().hourComponent, anchor: .top)
        } else if let first = vm.dayEvents.first {
            proxy.scrollTo(cal.component(.hour, from: first.start), anchor: .top)
        } else {
            proxy.scrollTo(8, anchor: .top) // default morning
        }
    }
}

