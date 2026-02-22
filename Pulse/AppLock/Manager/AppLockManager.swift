import EntropyCore
import Foundation

/// Manages app lock state and biometric authentication lifecycle.
///
/// Follows the same singleton pattern as `ThemeManager` and `AuthenticationManager`.
/// The `isAuthenticating` flag prevents re-locking when Face ID dialog causes
/// `sceneWillResignActive`/`sceneDidBecomeActive` without `sceneDidEnterBackground`.
@MainActor
final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    /// Whether the app is currently locked and showing the overlay.
    @Published private(set) var isLocked = false

    /// Whether to show the post-signup Face ID prompt sheet.
    @Published var showFaceIDPrompt = false

    /// Guards against re-locking during biometric dialog lifecycle events.
    private(set) var isAuthenticating = false

    private var appLockService: AppLockService?

    private init() {}

    /// Configure with the app lock service (called during app setup).
    func configure(with service: AppLockService) {
        appLockService = service

        // If app lock is enabled, start locked
        if service.isEnabled {
            isLocked = true
        }
    }

    // MARK: - Scene Lifecycle

    /// Called from `sceneDidEnterBackground`. Locks the app if enabled.
    func handleSceneDidEnterBackground() {
        guard let service = appLockService, service.isEnabled else { return }
        isLocked = true
    }

    /// Called from `sceneDidBecomeActive`. Attempts unlock if locked.
    /// Guards against the Face ID dialog triggering this method.
    func handleSceneDidBecomeActive() {
        guard !isAuthenticating else { return }
        guard let service = appLockService, service.isEnabled, isLocked else { return }
        Task { await attemptUnlock() }
    }

    // MARK: - Authentication

    /// Attempts biometric authentication to unlock the app.
    func attemptUnlock() async {
        guard let service = appLockService else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await service.authenticate(
                reason: AppLocalization.shared.localized("applock.auth_reason")
            )
            if success {
                isLocked = false
            }
        } catch {
            Logger.shared.service("App lock authentication failed: \(error)", level: .debug)
        }
    }

    // MARK: - Post-Signup Prompt

    /// Shows the Face ID prompt if the user hasn't been prompted yet and biometrics are available.
    func checkPostSignupPrompt() {
        guard let service = appLockService else { return }
        guard !service.hasPromptedFaceID, service.canEvaluateBiometrics() else { return }
        showFaceIDPrompt = true
    }

    /// User tapped "Enable" on the prompt. Validates biometrics then enables.
    func enableFromPrompt() async {
        guard let service = appLockService else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await service.authenticate(
                reason: AppLocalization.shared.localized("applock.enable_reason")
            )
            if success {
                service.isEnabled = true
            }
        } catch {
            Logger.shared.service("Face ID prompt auth failed: \(error)", level: .debug)
        }

        service.hasPromptedFaceID = true
        showFaceIDPrompt = false
    }

    /// User tapped "Not Now" on the prompt.
    func dismissPrompt() {
        guard let service = appLockService else { return }
        service.hasPromptedFaceID = true
        showFaceIDPrompt = false
    }

    // MARK: - Settings

    /// Whether app lock is enabled. Read-only for UI display.
    var isAppLockEnabled: Bool {
        appLockService?.isEnabled ?? false
    }

    /// Whether biometrics are available on this device.
    var canUseBiometrics: Bool {
        appLockService?.canEvaluateBiometrics() ?? false
    }

    /// Toggle app lock from Settings.
    /// Enabling requires biometric validation first; disabling is immediate.
    func toggleAppLock(enabled: Bool) async {
        guard let service = appLockService else { return }

        if enabled {
            isAuthenticating = true
            defer { isAuthenticating = false }

            do {
                let success = try await service.authenticate(
                    reason: AppLocalization.shared.localized("applock.enable_reason")
                )
                if success {
                    service.isEnabled = true
                    objectWillChange.send()
                }
            } catch {
                Logger.shared.service("App lock enable auth failed: \(error)", level: .debug)
            }
        } else {
            service.isEnabled = false
            isLocked = false
            objectWillChange.send()
        }
    }

    #if DEBUG
        /// For testing: configure with a mock service and reset state.
        func configureForTesting(with service: AppLockService) {
            appLockService = service
            isLocked = false
            isAuthenticating = false
            showFaceIDPrompt = false
        }
    #endif
}
