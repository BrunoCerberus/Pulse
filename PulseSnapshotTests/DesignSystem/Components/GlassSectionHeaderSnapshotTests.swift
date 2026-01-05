@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassSectionHeaderSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // MARK: - GlassSectionHeader Tests

    func testGlassSectionHeaderSimple() {
        let view = GlassSectionHeader("Breaking News")
            .frame(width: 393)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
