import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveAppLockService Tests", .serialized)
struct LiveAppLockServiceTests {
    /// Isolated Keychain service to avoid collisions with the app host.
    private static let testKeychainService = "com.pulse.applock.tests"
    private let keychain = KeychainManager(service: testKeychainService)
    private let defaults = UserDefaults(suiteName: "com.pulse.applock.tests")!

    init() {
        try? keychain.delete(for: "appLockEnabled")
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
