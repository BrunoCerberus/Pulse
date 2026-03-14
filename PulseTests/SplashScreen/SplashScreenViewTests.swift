import Foundation
@testable import Pulse
import Testing
import UIKit

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
    /// This test verifies the view renders without crashing (e.g. missing resources,
    /// broken modifiers), serving as a build-time smoke test.
    /// Note: Directly accessing view.body triggers @Environment outside a view hierarchy;
    /// using UIHostingController to properly install the view instead.
    @Test("SplashScreenView renders without crashing")
    func renders() {
        let view = SplashScreenView {}
        let controller = UIHostingController(rootView: view)
        _ = controller.view
    }
}
