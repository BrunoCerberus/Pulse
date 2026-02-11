import Foundation

/// Mock implementation of `AppLockService` for testing and previews.
final class MockAppLockService: AppLockService {
    var isEnabled: Bool = false
    var hasPromptedFaceID: Bool = false

    var canEvaluateResult: Bool = true
    var authenticateResult: Result<Bool, AppLockError> = .success(true)
    var authenticateCallCount = 0

    func canEvaluateBiometrics() -> Bool {
        canEvaluateResult
    }

    func authenticate(reason _: String) async throws -> Bool {
        authenticateCallCount += 1
        return try authenticateResult.get()
    }
}
