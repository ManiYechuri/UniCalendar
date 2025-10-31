import SwiftUI
import AppAuth

@main
struct UniCalendarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router = AppRouter()
    @StateObject private var auth = AuthViewModel(
        google: GoogleAuthAdapter(),
        microsoft: DummyMicrosoftAuthAdapter()
    )
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(router)
                .environmentObject(auth)
                .onOpenURL { url in
                    _ = GoogleAuthService.shared.resume(url)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task { await MainActor.run { SyncManager.shared.refreshAllAccounts() } }
                    }
                }
                .onAppear {
                    AccountStorage.shared.migrateAccountsSchemaIfNeeded()
                }
        }
    }
}


// Keep your temporary Microsoft stub so things compile
final class DummyMicrosoftAuthAdapter: AuthService {
    func signIn(presenting: UIViewController) async throws -> AuthUser {
        AuthUser(id: UUID().uuidString, email: "user@outlook.com", provider: "microsoft")
    }
}

