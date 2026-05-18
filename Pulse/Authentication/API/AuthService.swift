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
    /// Firebase anonymous user. Used only by the reviewer-only sign-in path
    /// (5-tap gesture on the logo in `SignInView`); real users never reach
    /// this provider.
    case anonymous
}

enum AuthError: Error, LocalizedError {
    case signInCancelled
    case invalidCredential
    case networkError
    case noCurrentUser
    /// Reviewer-only anonymous sign-in was rejected by the 60s throttle.
    /// Dedicated case so `AuthDomainInteractor` can skip Crashlytics +
    /// the `signIn(success: false)` analytics event for this specific
    /// failure — otherwise the throttle hits would pollute the very
    /// analytics surface the M3 / M9 fixes are trying to keep clean.
    case anonymousSignInThrottled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .signInCancelled: return "Sign in was cancelled"
        case .invalidCredential: return "Invalid credentials"
        case .networkError: return "Network error occurred"
        case .noCurrentUser: return "No user is currently signed in"
        case .anonymousSignInThrottled: return "Reviewer sign-in throttled"
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

    /// Sign in anonymously via Firebase Auth.
    ///
    /// Reviewer-only entry point so App Review can access auth-gated screens
    /// without us having to share OAuth credentials (and deal with Google /
    /// Apple ID 2FA reaching the reviewer). Triggered by the hidden 5-tap
    /// gesture on the logo in `SignInView`; the trigger is documented in
    /// App Store Connect → App Review Information.
    func signInAnonymously() -> AnyPublisher<AuthUser, Error>

    /// Sign out current user
    func signOut() -> AnyPublisher<Void, Error>

    /// Permanently delete the signed-in account.
    ///
    /// If Firebase reports `requiresRecentLogin`, this transparently re-authenticates
    /// the user with their original provider (Google/Apple) and retries the deletion.
    /// - Parameter viewController: Presenter for the Google re-auth sheet (ignored for Apple).
    func deleteAccount(presenting viewController: UIViewController) -> AnyPublisher<Void, Error>
}
