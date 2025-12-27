import Combine
import Foundation
import UIKit

/// Represents an authenticated user
struct AuthUser: Equatable, Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider
}

enum AuthProvider: String, Equatable, Codable {
    case google
    case apple
}

enum AuthError: Error, LocalizedError {
    case signInCancelled
    case invalidCredential
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .signInCancelled: return "Sign in was cancelled"
        case .invalidCredential: return "Invalid credentials"
        case .networkError: return "Network error occurred"
        case let .unknown(message): return message
        }
    }
}

protocol AuthService {
    /// Publisher for current authentication state
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { get }

    /// Current user (synchronous access)
    var currentUser: AuthUser? { get }

    /// Sign in with Google
    func signInWithGoogle(presenting viewController: UIViewController) -> AnyPublisher<AuthUser, Error>

    /// Sign in with Apple
    func signInWithApple() -> AnyPublisher<AuthUser, Error>

    /// Sign out current user
    func signOut() -> AnyPublisher<Void, Error>
}
