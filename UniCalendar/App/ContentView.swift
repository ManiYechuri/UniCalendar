import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        router.root
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter())
        .environmentObject(
            AuthViewModel(google: GoogleAuthService() as! AuthService, microsoft: MicrosoftAuthService())
        )
}

