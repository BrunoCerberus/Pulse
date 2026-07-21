import Combine
import FirebaseAuth
import Foundation

/// Anonymous (reviewer-only) sign-in lives in its own file to keep
/// `LiveAuthService.swift` under the SwiftLint file-length budget — same
/// reason `FirebaseUser+AuthUser.swift` was split out.
extension LiveAuthService {
    /// UserDefaults key holding the Unix timestamp of the last anonymous
    /// sign-in attempt. Kept out of Keychain because the value isn't
    /// sensitive and we deliberately want it to survive sign-out so a
    /// curious user can't bypass the throttle by signing out and retrying.
    static let anonymousSignInLastAttemptKey = "pulse.anonymousSignInLastAttempt"

    /// Minimum interval between anonymous sign-in attempts. Long enough to
    /// block accidental cascades from the hidden 5-tap gesture, short enough
    /// that an App Review reviewer who needs to retry isn't blocked.
    static let anonymousSignInThrottleSeconds: TimeInterval = 60

    /// Pure read: returns `true` if a previous attempt is still inside the
    /// throttle window. Does NOT update the timestamp — record it only on a
    /// confirmed Firebase success via `recordAnonymousSignInAttempt`. A
    /// transient Firebase failure shouldn't burn the reviewer's 60s window.
    static func isAnonymousSignInThrottled(
        now: TimeInterval = Date().timeIntervalSince1970,
        defaults: UserDefaults = .standard,
        throttleSeconds: TimeInterval = anonymousSignInThrottleSeconds,
    ) -> Bool {
        let lastAttempt = defaults.double(forKey: anonymousSignInLastAttemptKey)
        guard lastAttempt > 0 else { return false }
        return now - lastAttempt < throttleSeconds
    }

    /// Records a successful anonymous sign-in attempt. Subsequent calls to
    /// `isAnonymousSignInThrottled` will return `true` for the next
    /// `throttleSeconds` seconds.
    static func recordAnonymousSignInAttempt(
        at now: TimeInterval = Date().timeIntervalSince1970,
        defaults: UserDefaults = .standard,
    ) {
        defaults.set(now, forKey: anonymousSignInLastAttemptKey)
    }

    /// Reviewer-only path documented in App Store Connect → App Review
    /// Information. Triggered by the 5-tap gesture on the logo in
    /// `SignInView`. Firebase still issues a real UID so the rest of the app
    /// (Supabase fetches, CloudKit, StoreKit) works identically to a
    /// regular sign-in.
    func signInAnonymously() -> AnyPublisher<AuthUser, Error> {
        Future { promise in
            let promise = UncheckedSendableBox(value: promise)

            if Self.isAnonymousSignInThrottled() {
                promise.value(.failure(AuthError.anonymousSignInThrottled))
                return
            }

            Task {
                do {
                    let authResult = try await Auth.auth().signInAnonymously()
                    if let user = authResult.user.toAuthUser() {
                        // Only burn the throttle window on a confirmed
                        // Firebase success — a transient backend / network
                        // failure shouldn't lock the reviewer out for 60s.
                        Self.recordAnonymousSignInAttempt()
                        promise.value(.success(user))
                    } else {
                        promise.value(.failure(AuthError.unknown("Failed to create anonymous user")))
                    }
                } catch {
                    promise.value(.failure(AuthError.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
