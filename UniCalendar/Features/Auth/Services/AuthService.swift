import UIKit

protocol AuthService {
    @MainActor
    func signIn(presenting: UIViewController) async throws -> AuthUser
}

