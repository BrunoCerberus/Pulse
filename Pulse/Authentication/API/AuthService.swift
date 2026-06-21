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
    /// WebAuthn / Passkey sign-in via `ASAuthorizationPasswordProvider`.
    case passkey
}

enum AuthError: Error, LocalizedError {
    case signInCancelled
    case invalidCredential
    case networkError
    case noCurrentUser
    /// `signInWithPasskey()` completed successfully but no credentials were found.
    case noPasskeysAvailable
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
        case .noPasskeysAvailable: return "No passkeys found on this device"
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

    /// Sign in with Passkey (WebAuthn).
    ///
    /// Checks for stored passkeys; if multiple exist presents a username picker.
    /// If none exist, returns `.noPasskeys` so the caller can offer registration
    /// instead. On success, stores a `pulse.userHasPasskey` flag for later
    /// provider detection and passkey management UI.
    func signInWithPasskey() -> AnyPublisher<AuthUser, Error>

    /// Register a new Passkey for the current Firebase user.
    ///
    /// Uses `ASAuthorizationPasswordProvider` to create a credential and links it
    /// to the existing Firebase account via `link(with:)`. Returns `nil` if the
    /// user already has a passkey registered.
    func registerPasskey() -> AnyPublisher<AuthUser, Error>

    /// Retrieve available passkey usernames for the current device.
    func getAvailablePasskeys() -> AnyPublisher<[String], Error>

    /// Delete a stored passkey by username.
    ///
    /// Apple requires the user to re-authenticate before deleting a passkey. The
    /// caller must handle the re-auth flow if needed.
    func deletePasskey(username: String) -> AnyPublisher<Void, Error>

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
