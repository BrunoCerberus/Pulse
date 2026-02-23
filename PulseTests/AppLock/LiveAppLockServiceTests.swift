import Foundation
@testable import Pulse
import Testing

/// In-memory `KeychainStore` that avoids real Keychain entitlement requirements in unit tests.
private final class InMemoryKeychainStore: KeychainStore {
    private var store = [String: String]()

    func exists(for key: String) -> Bool {
        store[key] != nil
    }

    func save(_ value: String, for key: String) throws {
        store[key] = value
    }

    func delete(for key: String) throws {
        store.removeValue(forKey: key)
    }
}

@Suite("LiveAppLockService Tests", .serialized)
struct LiveAppLockServiceTests {
    private let keychain = InMemoryKeychainStore()
    private let defaults = UserDefaults(suiteName: "com.pulse.applock.tests")!

    init() {
        defaults.removePersistentDomain(forName: "com.pulse.applock.tests")
    }

    private func makeSUT() -> LiveAppLockService {
        LiveAppLockService(keychain: keychain, defaults: defaults)
    }

    @Test("isEnabled round-trips through Keychain")
    func isEnabledRoundTrips() {
        let sut = makeSUT()
        #expect(sut.isEnabled == false)

        sut.isEnabled = true
        #expect(sut.isEnabled == true)

        sut.isEnabled = false
        #expect(sut.isEnabled == false)
    }

    @Test("hasPromptedFaceID round-trips through UserDefaults")
    func hasPromptedFaceIDRoundTrips() {
        let sut = makeSUT()
        #expect(sut.hasPromptedFaceID == false)

        sut.hasPromptedFaceID = true
        #expect(sut.hasPromptedFaceID == true)

        sut.hasPromptedFaceID = false
        #expect(sut.hasPromptedFaceID == false)
    }

    @Test("canEvaluateBiometrics returns false on simulator")
    func canEvaluateBiometricsOnSimulator() {
        let sut = makeSUT()
        #expect(sut.canEvaluateBiometrics() == false)
    }

    @Test("migrates from UserDefaults to Keychain on init")
    func migratesFromUserDefaults() {
        // Set up legacy state before creating the service
        defaults.set(true, forKey: "pulse.appLockEnabled")

        let sut = makeSUT()

        #expect(sut.isEnabled == true)
        // Legacy key should be removed after migration
        #expect(defaults.object(forKey: "pulse.appLockEnabled") == nil)
    }
}
