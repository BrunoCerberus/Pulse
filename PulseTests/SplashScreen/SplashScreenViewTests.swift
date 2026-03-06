import Foundation
@testable import Pulse
import Testing

@Suite("SplashScreenView Tests")
@MainActor
struct SplashScreenViewTests {
    @Test("SplashScreenView initializes with onComplete callback")
    func initializesWithCallback() {
        var callbackInvoked = false
        let view = SplashScreenView {
            callbackInvoked = true
        }

        view.onComplete()
        #expect(callbackInvoked == true)
    }

    /// Visual regression coverage is handled by snapshot tests in PulseSnapshotTests.
    /// This test verifies the view body can be evaluated without crashing (e.g. missing
    /// resources, broken modifiers), serving as a build-time smoke test.
    @Test("SplashScreenView body evaluates without crashing")
    func bodyEvaluates() {
        let view = SplashScreenView {}
        _ = view.body
    }
}
