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

    /// Returns `.success` and records `now` as the latest attempt when the
    /// throttle window has elapsed; returns `.failure` with a human-readable
    /// message otherwise. Extracted from `signInAnonymously` so it can be
    /// unit-tested with a custom `UserDefaults` suite and clock.
    static func checkAnonymousSignInThrottle(
        now: TimeInterval = Date().timeIntervalSince1970,
        defaults: UserDefaults = .standard,
        throttleSeconds: TimeInterval = anonymousSignInThrottleSeconds
    ) -> Result<Void, AuthError> {
        let lastAttempt = defaults.double(forKey: anonymousSignInLastAttemptKey)
        if lastAttempt > 0, now - lastAttempt < throttleSeconds {
            let remaining = Int(throttleSeconds - (now - lastAttempt))
            return .failure(.unknown("Reviewer sign-in throttled. Try again in \(remaining)s."))
        }
        defaults.set(now, forKey: anonymousSignInLastAttemptKey)
        return .success(())
    }

    /// Reviewer-only path documented in App Store Connect → App Review
    /// Information. Triggered by the 5-tap gesture on the logo in
    /// `SignInView`. Firebase still issues a real UID so the rest of the app
    /// (Supabase fetches, CloudKit, StoreKit) works identically to a
    /// regular sign-in.
    func signInAnonymously() -> AnyPublisher<AuthUser, Error> {
        Future { promise in
            let promise = UncheckedSendableBox(value: promise)

            if case let .failure(error) = Self.checkAnonymousSignInThrottle() {
                promise.value(.failure(error))
                return
            }

            Task {
                do {
                    let authResult = try await Auth.auth().signInAnonymously()
                    if let user = authResult.user.toAuthUser() {
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
