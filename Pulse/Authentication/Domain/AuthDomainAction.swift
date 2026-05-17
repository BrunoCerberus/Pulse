import UIKit

/// Actions that can be dispatched to the Authentication domain interactor.
///
/// These actions manage user authentication via Firebase Auth,
/// supporting Google Sign-In and Apple Sign-In providers.
enum AuthDomainAction {
    // MARK: - Sign In

    /// Initiate Google Sign-In flow.
    /// - Parameter presenting: The view controller to present the Google Sign-In UI from.
    case signInWithGoogle(presenting: UIViewController)

    /// Initiate Apple Sign-In flow using AuthenticationServices.
    /// Presents the native Apple Sign-In sheet.
    case signInWithApple

    /// Initiate anonymous Firebase sign-in.
    ///
    /// Reviewer-only path — wired to the hidden 5-tap gesture on the logo in
    /// `SignInView`. Lets App Review reach auth-gated screens without shared
    /// OAuth credentials. Trigger is documented in App Store Connect.
    case signInAnonymously

    // MARK: - Sign Out

    /// Sign out the current user from Firebase Auth.
    /// Clears local session and returns to sign-in screen.
    case signOut

    // MARK: - Error Handling

    /// Clear any displayed authentication error.
    case clearError
}
