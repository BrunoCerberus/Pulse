@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class PaywallViewSnapshotTests: XCTestCase {
    private var window: UIWindow!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func testPaywallViewLoading() {
        // Use preview ServiceLocator which has MockStoreKitService configured
        let viewModel = PaywallViewModel(serviceLocator: .preview)

        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Add to window to trigger full view lifecycle
        window.rootViewController = controller
        controller.view.layoutIfNeeded()

        // Capture loading state immediately before products load
        assertSnapshot(
            of: controller,
            as: .image(on: iPhoneAirConfig, precision: 0.99),
            record: false
        )
    }

    func testPaywallViewSuccess() {
        let viewModel = PaywallViewModel(serviceLocator: .preview)

        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Add to window to trigger full view lifecycle
        window.rootViewController = controller
        controller.view.layoutIfNeeded()

        // Wait for Combine pipeline to load products and render success state
        let expectation = XCTestExpectation(description: "Wait for products to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        assertSnapshot(
            of: controller,
            as: .image(on: iPhoneAirConfig, precision: 0.99),
            record: false
        )
    }
}
