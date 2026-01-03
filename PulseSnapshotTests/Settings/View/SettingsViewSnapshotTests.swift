@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsViewSnapshotTests: XCTestCase {
    private var window: UIWindow!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    override func setUp() {
        super.setUp()
        // Set authenticated state before SettingsViewModel is created
        AuthenticationManager.shared.setAuthenticatedForTesting(.mock)

        // Create a window for proper view lifecycle
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        AuthenticationManager.shared.setUnauthenticatedForTesting()
        super.tearDown()
    }

    func testSettingsViewInitial() {
        // Use preview ServiceLocator which has all mocks configured
        let serviceLocator = ServiceLocator.preview

        // Create view with NavigationStack
        let view = NavigationStack {
            SettingsView(serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        // Add to window to trigger full view lifecycle
        window.rootViewController = controller
        controller.view.layoutIfNeeded()

        // Wait for Combine pipeline and SwiftUI to settle
        let expectation = XCTestExpectation(description: "Wait for view to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        assertSnapshot(
            of: controller,
            as: .image(on: iPhoneAirConfig, precision: 0.99),
            record: false
        )
    }
}
