@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class PaywallViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection()
    )

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StoreKitService.self, instance: MockStoreKitService())
    }

    func testPaywallViewLoading() {
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testPaywallViewSuccess() {
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Wait for products to load (mock returns empty array quickly)
        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testPaywallViewPremiumUser() {
        let mockService = MockStoreKitService(isPremium: true)
        serviceLocator.register(StoreKitService.self, instance: mockService)

        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }
}
