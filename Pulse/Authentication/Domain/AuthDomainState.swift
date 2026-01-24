import Foundation

/// Represents the domain state for the Authentication feature.
///
/// This state is owned by `AuthDomainInteractor` and published via `statePublisher`.
/// Authentication supports Google Sign-In and Sign in with Apple via Firebase Auth.
struct AuthDomainState: Equatable {
    /// Indicates whether a sign-in operation is in progress.
    var isLoading: Bool

    /// Error message to display, if sign-in failed.
    var error: String?

    /// Currently authenticated user, or `nil` if not signed in.
    var user: AuthUser?

    /// Creates the default initial state.
    static var initial: AuthDomainState {
        AuthDomainState(
            isLoading: false,
            error: nil,
            user: nil
        )
    }
}
