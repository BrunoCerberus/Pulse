import EntropyCore
import LocalAuthentication

/// Abstraction for key-value secure storage used by services that persist
/// sensitive strings (app-lock state, APNs device token, etc).
/// Production uses `KeychainManager`; tests use an in-memory implementation.
protocol KeychainStore {
    func exists(for key: String) -> Bool
    func save(_ value: String, for key: String) throws
    func retrieve(for key: String) throws -> String
    func delete(for key: String) throws
}

extension KeychainManager: KeychainStore {}

/// Live implementation of `AppLockService` using LocalAuthentication framework.
///
/// Stores the lock-enabled state in the Keychain (tamper-resistant on non-jailbroken devices)
/// and uses `deviceOwnerAuthentication` policy so the system passcode serves as a
/// fallback when biometrics are unavailable or locked out.
final class LiveAppLockService: AppLockService {
    private enum Keys {
        static let appLockEnabled = "appLockEnabled"
        static let hasPromptedFaceID = "pulse.hasPromptedFaceID"
    }

    static let keychainService = "com.pulse.applock"

    private let keychain: KeychainStore
    private let defaults: UserDefaults

    var isEnabled: Bool {
        get { keychain.exists(for: Keys.appLockEnabled) }
        set {
            if newValue {
                try? keychain.save("1", for: Keys.appLockEnabled)
            } else {
                try? keychain.delete(for: Keys.appLockEnabled)
            }
        }
    }

    var hasPromptedFaceID: Bool {
        get { defaults.bool(forKey: Keys.hasPromptedFaceID) }
        set { defaults.set(newValue, forKey: Keys.hasPromptedFaceID) }
    }

    init(keychain: KeychainStore = KeychainManager(service: keychainService),
         defaults: UserDefaults = .standard)
    {
        self.keychain = keychain
        self.defaults = defaults
        migrateFromUserDefaultsIfNeeded()
    }

    func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()

        // Use deviceOwnerAuthentication so the system passcode is offered as fallback
        // when biometrics are unavailable, locked out, or fail repeatedly.
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Only the genuinely-unenforceable case (no device passcode set) auto-
            // disables the lock and unlocks — trapping the user behind a gate that
            // can never be satisfied is pure harm, and a passcode-less device has
            // no OS-level security to enforce anyway. ANY other (transient/
            // unexpected) failure stays fail-CLOSED. See `isUnenforceableLockError`.
            if Self.isUnenforceableLockError(error) {
                isEnabled = false
                return true
            }
            throw AppLockError.authenticationFailed
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
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

    /// Whether a `canEvaluatePolicy(.deviceOwnerAuthentication)` failure means
    /// the lock is genuinely unenforceable — i.e. the device has no passcode set
    /// (`LAError.passcodeNotSet`) — as opposed to a transient/unexpected failure
    /// we should treat as fail-closed. Static + `NSError`-based so the decision
    /// is unit-testable without a live `LAContext`.
    static func isUnenforceableLockError(_ error: NSError?) -> Bool {
        guard let error, error.domain == LAError.errorDomain else { return false }
        return LAError.Code(rawValue: error.code) == .passcodeNotSet
    }

    /// One-time migration from UserDefaults to Keychain for existing users.
    private func migrateFromUserDefaultsIfNeeded() {
        let legacyKey = "pulse.appLockEnabled"
        guard defaults.bool(forKey: legacyKey) else { return }
        // Migrate: write to Keychain, then remove old UserDefaults entry
        try? keychain.save("1", for: Keys.appLockEnabled)
        defaults.removeObject(forKey: legacyKey)
    }
}
