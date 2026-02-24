import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying PremiumGateView layout at accessibility text sizes.
/// Validates icon sizing and layout adaptation at accessibility Dynamic Type sizes.
@MainActor
final class PremiumGateViewAccessibilitySnapshotTests: XCTestCase {
    func testPremiumGateViewAccessibilitySize() {
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: .preview
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: false
        )
    }

    func testPremiumGateViewExtraExtraLargeSize() {
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: .preview
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: false
        )
    }
}
