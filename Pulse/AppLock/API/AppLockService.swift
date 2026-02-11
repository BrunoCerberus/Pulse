import Foundation

/// Errors that can occur during app lock operations.
enum AppLockError: Error, Equatable {
    case biometricsUnavailable
    case authenticationFailed
    case userCancelled
}

/// Protocol for managing biometric app lock functionality.
protocol AppLockService: AnyObject {
    /// Whether the app lock is currently enabled by the user.
    var isEnabled: Bool { get set }

    /// Whether the user has already been prompted to enable Face ID after sign-up.
    var hasPromptedFaceID: Bool { get set }

    /// Checks if biometric authentication is available on this device.
    func canEvaluateBiometrics() -> Bool

    /// Attempts biometric authentication.
    /// - Parameter reason: The reason string shown in the biometric prompt.
    /// - Returns: `true` if authentication succeeded.
    /// - Throws: `AppLockError` if authentication fails.
    func authenticate(reason: String) async throws -> Bool
}
