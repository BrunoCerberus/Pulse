@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassSectionHeaderSnapshotTests: XCTestCase {
    // MARK: - GlassSectionHeader Tests

    func testGlassSectionHeaderSimple() {
        let view = GlassSectionHeader("Breaking News")
            .frame(width: 393)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testGlassSectionHeaderWithSubtitle() {
        let view = GlassSectionHeader(
            "Top Stories",
            subtitle: "Updated 5 minutes ago"
        )
        .frame(width: 393)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testGlassSectionHeaderWithAction() {
        let view = GlassSectionHeader(
            "Top Stories",
            subtitle: "Updated 5 minutes ago",
            actionTitle: "See All"
        ) {}
            .frame(width: 393)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - StickySectionHeader Tests

    func testStickySectionHeaderWithBackground() {
        let view = StickySectionHeader("Technology")
            .frame(width: 393)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testStickySectionHeaderWithoutBackground() {
        let view = StickySectionHeader("Technology", showBackground: false)
            .frame(width: 393)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
