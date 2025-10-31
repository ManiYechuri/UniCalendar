import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .signedOut
    @Published var isBusy = false
    
    private let google: AuthService
    private let microsoft: AuthService
    
    init(google: AuthService, microsoft: AuthService) {
        self.google = google
        self.microsoft = microsoft
    }
    
    func signInWithGoogle() async { await signIn(via: google, provider: "google") }
    func signInWithMicrosoft() async { await signIn(via: microsoft, provider: "outlook") }
    
    private func signIn(via service: AuthService, provider: String) async {
            guard !isBusy else { return }
            guard let presenter = UIApplication.shared.topViewController else {
                state = .error("No presenter available"); return
            }
            isBusy = true; defer { isBusy = false }

            do {
                let user = try await service.signIn(presenting: presenter)
                print("User details : \(user.email), \(user.id)")
                state = .authenticated(user)

                // Save account immediately
                let email = user.email.lowercased()
                AccountStorage.shared.upsertAccount(email: email, provider: provider)

                // Tell the app shell to switch screens
                NotificationCenter.default.post(name: .accountsDidChange, object: nil)

                // Kick sync in the background (don’t block UI)
                Task { await MainActor.run { SyncManager.shared.refreshAllAccounts() } }

            } catch {
                state = .error(error.localizedDescription)
            }
        }
}

