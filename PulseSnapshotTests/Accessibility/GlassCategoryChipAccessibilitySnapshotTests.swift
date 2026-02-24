import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying GlassCategoryButton layout at accessibility text sizes.
/// Validates the minWidth adaptation when Dynamic Type reaches accessibility sizes.
@MainActor
final class GlassCategoryChipAccessibilitySnapshotTests: XCTestCase {
    func testGlassCategoryButtonAccessibilitySize() {
        let view = GlassCategoryButton(
            category: .technology,
            isSelected: false,
            action: {}
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: true
        )
    }

    func testGlassCategoryButtonExtraExtraLargeSize() {
        let view = GlassCategoryButton(
            category: .technology,
            isSelected: false,
            action: {}
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirExtraExtraLarge),
            record: true
        )
    }

    func testGlassCategoryButtonSelectedAccessibilitySize() {
        let view = GlassCategoryButton(
            category: .technology,
            isSelected: true,
            action: {}
        )
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: true
        )
    }
}
