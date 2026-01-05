@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SplashScreenViewSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    func testSplashScreenViewInitial() {
        // Create splash screen view with empty completion handler
        let view = SplashScreenView(onComplete: {})
            .frame(width: 393, height: 852)

        let controller = UIHostingController(rootView: view)

        // Wait a bit for initial animation state to settle
        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testSplashScreenViewAnimated() {
        let view = SplashScreenView(onComplete: {})
            .frame(width: 393, height: 852)

        let controller = UIHostingController(rootView: view)

        // Wait for logo animation to complete
        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
