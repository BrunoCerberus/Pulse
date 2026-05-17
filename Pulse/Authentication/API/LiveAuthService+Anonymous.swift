import Combine
import FirebaseAuth
import Foundation

/// Anonymous (reviewer-only) sign-in lives in its own file to keep
/// `LiveAuthService.swift` under the SwiftLint file-length budget — same
/// reason `FirebaseUser+AuthUser.swift` was split out.
extension LiveAuthService {
    /// Reviewer-only path documented in App Store Connect → App Review
    /// Information. Triggered by the 5-tap gesture on the logo in
    /// `SignInView`. Firebase still issues a real UID so the rest of the app
    /// (Supabase fetches, CloudKit, StoreKit) works identically to a
    /// regular sign-in.
    func signInAnonymously() -> AnyPublisher<AuthUser, Error> {
        Future { promise in
            let promise = UncheckedSendableBox(value: promise)
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
