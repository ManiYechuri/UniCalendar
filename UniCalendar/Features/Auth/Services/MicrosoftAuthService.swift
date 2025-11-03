import UIKit

struct MicrosoftAuthService: AuthService {
    func signIn(presenting: UIViewController) async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 300_000_000)
        return AuthUser(id: UUID().uuidString, email: "user@outlook.com", provider: "microsoft")
    }
    
    func signIn() async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 300_000_000)
        return AuthUser(id: UUID().uuidString, email: "user@outlook.com", provider: "microsoft")
    }
}
