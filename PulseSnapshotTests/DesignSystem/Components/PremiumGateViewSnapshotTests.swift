@testable import Pulse
import EntropyCore
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class PremiumGateViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()

        // Register required services for PremiumGateView
        let mockStoreKitService = MockStoreKitService(isPremium: false)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)
    }

    override func tearDown() {
        serviceLocator = nil
        super.tearDown()
    }

    // MARK: - Daily Digest Feature Gate

    func testPremiumGateViewDailyDigest() {
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: serviceLocator
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    // MARK: - Article Summarization Feature Gate

    func testPremiumGateViewArticleSummarization() {
        let view = PremiumGateView(
            feature: .articleSummarization,
            serviceLocator: serviceLocator
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    // MARK: - Light Mode Tests

    func testPremiumGateViewDailyDigestLightMode() {
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: serviceLocator
        )

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAirLight, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }
}
