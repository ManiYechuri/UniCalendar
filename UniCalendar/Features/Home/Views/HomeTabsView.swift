import SwiftUI

struct HomeTabsView: View {
    var body: some View {
        TabView {
            WeekCalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationView { SyncView() }
                    .tabItem { Label("Sync", systemImage: "arrow.2.circlepath") }
            NavigationView { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

