import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class RootViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(AuthService.self, instance: MockAuthService())
    }

    // MARK: - Loading State Tests

    func testRootViewLoadingState() {
        // Test the loading view directly since RootView's loading state is controlled by AuthenticationManager
        let loadingView = ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }

        let controller = UIHostingController(rootView: loadingView)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testRootViewLoadingStateLightMode() {
        // Test loading view in light mode - background stays black per design
        let loadingView = ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }

        let controller = UIHostingController(rootView: loadingView)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Sign In State Tests

    func testRootViewUnauthenticatedState() {
        // Test the SignInView which is shown when unauthenticated
        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testRootViewUnauthenticatedStateLightMode() {
        let view = SignInView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }
}
