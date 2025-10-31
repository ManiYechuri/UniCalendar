import SwiftUI

struct LaunchView: View {
    @State private var hasAccounts = !AccountStorage.shared.connectedAccounts().isEmpty


    var body: some View {
        Group {
            if hasAccounts {
                HomeTabsView()
            } else {
                LoginView()
            }
        }
        .onAppear { hasAccounts = !AccountStorage.shared.connectedAccounts().isEmpty }
        .onReceive(NotificationCenter.default.publisher(for: .accountsDidChange)) { _ in
            hasAccounts = true
        }
    }
}

