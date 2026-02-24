import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests verifying GlassArticleCard layout at accessibility text sizes.
/// Validates the HStack-to-VStack transition from Phase 1 Dynamic Type adaptation.
@MainActor
final class GlassArticleCardAccessibilitySnapshotTests: XCTestCase {
    private var snapshotArticle: Article {
        Article(
            id: "a11y-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features for iOS Development",
            description: "Apple announces major updates to SwiftUI including improved performance and new APIs",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
            category: .technology
        )
    }

    // MARK: - Accessibility Size (VStack layout)

    func testGlassArticleCardAccessibilitySize() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = GlassArticleCard(
            item: item,
            isBookmarked: false,
            onTap: {},
            onBookmark: {},
            onShare: {}
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

    func testGlassArticleCardExtraExtraLargeSize() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = GlassArticleCard(
            item: item,
            isBookmarked: false,
            onTap: {},
            onBookmark: {},
            onShare: {}
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

    // MARK: - Compact Variant

    func testGlassArticleCardCompactAccessibilitySize() {
        let view = GlassArticleCardCompact(
            title: "Quick Update on Markets Today With Some Extra Text",
            sourceName: "Bloomberg",
            imageURL: nil,
            onTap: {}
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
