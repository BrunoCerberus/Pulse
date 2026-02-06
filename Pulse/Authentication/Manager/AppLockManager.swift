import Combine
import EntropyCore
import LocalAuthentication
import SwiftUI

/// Manages biometric app lock state and preferences.
///
/// Singleton that handles FaceID/TouchID authentication, privacy overlay
/// for the app switcher, and grace period logic for background transitions.
@MainActor
final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    /// Whether the app is currently locked and requires biometric authentication
    @Published private(set) var isLocked: Bool

    /// Whether the privacy blur overlay should be shown (app switcher)
    @Published private(set) var isPrivacyOverlayActive = false

    /// Whether biometric lock is enabled by the user
    @Published var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: Keys.biometricEnabled)
        }
    }

    /// Timestamp when app entered background (for grace period calculation)
    private var backgroundTimestamp: Date?

    /// Whether a biometric/passcode evaluation is in progress.
    /// Used to suppress the privacy overlay during the FaceID system dialog.
    private var isAuthenticating = false

    /// Whether sceneDidEnterBackground was called (as opposed to just sceneWillResignActive).
    /// The FaceID dialog only triggers resignActive/becomeActive — NOT enterBackground.
    /// Re-locking only happens when the app actually went to background.
    private var didEnterBackground = false

    /// Grace period in seconds — skip re-auth for brief app switches
    private let gracePeriod: TimeInterval = 5.0

    private enum Keys {
        static let biometricEnabled = "pulse.biometricEnabled"
        static func hasPromptedBiometric(for uid: String) -> String {
            "pulse.hasPromptedBiometric.\(uid)"
        }
    }

    private init() {
        let enabled = UserDefaults.standard.bool(forKey: Keys.biometricEnabled)
        isBiometricEnabled = enabled
        // Cold start: if biometric is enabled, start locked
        isLocked = enabled
    }

    // MARK: - Biometric Info

    /// The type of biometric authentication available on this device
    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Whether any biometric authentication is available
    var isBiometricAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Display name for the current biometric type
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometrics"
        }
    }

    /// SF Symbol name for the current biometric type
    var biometricIconName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        @unknown default: return "lock.shield"
        }
    }

    // MARK: - Authentication

    /// Authenticate using biometrics only (FaceID/TouchID)
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Pulse"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            Logger.shared.service("Biometric auth failed: \(error.localizedDescription)", level: .debug)
            return false
        }
    }

    /// Authenticate using device passcode as fallback
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Pulse"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            Logger.shared.service("Passcode auth failed: \(error.localizedDescription)", level: .debug)
            return false
        }
    }

    // MARK: - Scene Lifecycle

    /// Called when scene resigns active (entering app switcher)
    func handleSceneWillResignActive() {
        // Don't show privacy overlay while FaceID/passcode dialog is up
        guard isBiometricEnabled, !isAuthenticating else { return }
        isPrivacyOverlayActive = true
    }

    /// Called when scene enters background
    func handleSceneDidEnterBackground() {
        backgroundTimestamp = Date()
        didEnterBackground = true
    }

    /// Called when scene becomes active (returning from background/app switcher)
    func handleSceneDidBecomeActive() {
        isPrivacyOverlayActive = false

        guard isBiometricEnabled else { return }

        // Only re-lock if the app actually went to background.
        // The FaceID/passcode system dialog only triggers resignActive/becomeActive
        // WITHOUT enterBackground — so we must not re-lock for those transitions.
        guard didEnterBackground else { return }
        didEnterBackground = false

        // Check grace period
        if let timestamp = backgroundTimestamp,
           Date().timeIntervalSince(timestamp) < gracePeriod
        {
            // Within grace period — skip re-auth
            return
        }

        if !isLocked {
            isLocked = true
        }
    }

    /// Lock the app and immediately trigger biometric authentication.
    /// Used after enabling biometric from the opt-in dialog.
    func lockAndAuthenticate() {
        isLocked = true
        Task {
            _ = await authenticate()
        }
    }

    // MARK: - Preference Management

    func enableBiometric() {
        isBiometricEnabled = true
    }

    func disableBiometric() {
        isBiometricEnabled = false
        isLocked = false
    }

    // MARK: - Per-User Opt-In Tracking

    /// Whether the opt-in dialog has been shown to this user
    func hasPromptedForBiometric(userUID: String) -> Bool {
        UserDefaults.standard.bool(forKey: Keys.hasPromptedBiometric(for: userUID))
    }

    /// Mark that the opt-in dialog has been shown to this user
    func markPrompted(for userUID: String) {
        UserDefaults.standard.set(true, forKey: Keys.hasPromptedBiometric(for: userUID))
    }

    /// Whether we should show the biometric opt-in dialog for this user
    func shouldShowOptIn(for userUID: String) -> Bool {
        isBiometricAvailable && !hasPromptedForBiometric(userUID: userUID)
    }

    // MARK: - Testing Helpers

    #if DEBUG
        func unlockForTesting() {
            isLocked = false
            isPrivacyOverlayActive = false
        }

        func resetForTesting() {
            isLocked = false
            isPrivacyOverlayActive = false
            isBiometricEnabled = false
            isAuthenticating = false
            didEnterBackground = false
            backgroundTimestamp = nil
        }
    #endif
}
