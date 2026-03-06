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

        // Verify callback is callable
        view.onComplete()
        #expect(callbackInvoked == true)
    }

    @Test("SplashScreenView body is accessible")
    func bodyIsAccessible() {
        let view = SplashScreenView {}
        // View can be created without crashing
        _ = view.body
    }
}
