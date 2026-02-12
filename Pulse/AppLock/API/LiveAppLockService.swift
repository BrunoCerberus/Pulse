import LocalAuthentication

/// Live implementation of `AppLockService` using LocalAuthentication framework.
final class LiveAppLockService: AppLockService {
    private enum Keys {
        static let appLockEnabled = "pulse.appLockEnabled"
        static let hasPromptedFaceID = "pulse.hasPromptedFaceID"
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.appLockEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.appLockEnabled) }
    }

    var hasPromptedFaceID: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasPromptedFaceID) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasPromptedFaceID) }
    }

    func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = ""

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AppLockError.biometricsUnavailable
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw AppLockError.userCancelled
            default:
                throw AppLockError.authenticationFailed
            }
        }
    }
}
