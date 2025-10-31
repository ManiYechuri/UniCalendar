import Foundation

struct AuthUser: Equatable {
    let id: String
    let email: String
    let provider: String
}

enum AuthState: Equatable {
    case signedOut
    case authenticated(AuthUser)
    case error(String)
}

