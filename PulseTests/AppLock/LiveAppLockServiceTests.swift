import Foundation
@testable import Pulse
import Testing

@Suite("LiveAppLockService Tests")
struct LiveAppLockServiceTests {
    let sut = LiveAppLockService()
    let testDefaults = UserDefaults.standard

    init() {
        // Clean up test keys before each test
        testDefaults.removeObject(forKey: "pulse.appLockEnabled")
        testDefaults.removeObject(forKey: "pulse.hasPromptedFaceID")
    }

    @Test("isEnabled round-trips through UserDefaults")
    func isEnabledRoundTrips() {
        #expect(sut.isEnabled == false)

        sut.isEnabled = true
        #expect(sut.isEnabled == true)
        #expect(testDefaults.bool(forKey: "pulse.appLockEnabled") == true)

        sut.isEnabled = false
        #expect(sut.isEnabled == false)
        #expect(testDefaults.bool(forKey: "pulse.appLockEnabled") == false)
    }

    @Test("hasPromptedFaceID round-trips through UserDefaults")
    func hasPromptedFaceIDRoundTrips() {
        #expect(sut.hasPromptedFaceID == false)

        sut.hasPromptedFaceID = true
        #expect(sut.hasPromptedFaceID == true)
        #expect(testDefaults.bool(forKey: "pulse.hasPromptedFaceID") == true)

        sut.hasPromptedFaceID = false
        #expect(sut.hasPromptedFaceID == false)
    }

    @Test("canEvaluateBiometrics returns false on simulator")
    func canEvaluateBiometricsOnSimulator() {
        // Biometrics are not available on simulator
        #expect(sut.canEvaluateBiometrics() == false)
    }
}
