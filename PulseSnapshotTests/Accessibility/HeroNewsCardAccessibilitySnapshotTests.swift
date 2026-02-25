import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying HeroNewsCard layout at accessibility text sizes.
/// Validates expanded card width and increased line limits.
@MainActor
final class HeroNewsCardAccessibilitySnapshotTests: XCTestCase {
    private var snapshotArticle: ArticleViewItem {
        ArticleViewItem(
            from: Article(
                title: "Breaking: Major Climate Summit Reaches Historic Agreement on Carbon Emissions",
                source: ArticleSource(id: nil, name: "Reuters"),
                url: "https://example.com",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )
    }

    func testHeroNewsCardAccessibilitySize() {
        let view = HeroNewsCard(
            item: snapshotArticle,
            onTap: {}
        )
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirAccessibility),
            record: false
        )
    }

    func testHeroNewsCardExtraExtraLargeSize() {
        let view = HeroNewsCard(
            item: snapshotArticle,
            onTap: {}
        )
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
