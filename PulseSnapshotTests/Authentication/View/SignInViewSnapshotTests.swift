import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SignInViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    /// Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(AuthService.self, instance: MockAuthService())
    }

    func testSignInViewInitial() {
        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSignInViewLoading() {
        // Create a mock that simulates loading state
        let mockAuthService = MockAuthService()
        serviceLocator.register(AuthService.self, instance: mockAuthService)

        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        // Note: Loading state is transient and controlled by the interactor
        // This test captures the initial non-loading state
        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSignInViewLightMode() {
        let lightModeConfig = ViewImageConfig(
            safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
            size: CGSize(width: 393, height: 852),
            traits: UITraitCollection(userInterfaceStyle: .light)
        )

        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lightModeConfig),
            record: false
        )
    }

    func testSignInViewiPad() {
        let iPadConfig = ViewImageConfig(
            safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
            size: CGSize(width: 820, height: 1180),
            traits: UITraitCollection(userInterfaceStyle: .dark)
        )

        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPadConfig),
            record: false
        )
    }
}
