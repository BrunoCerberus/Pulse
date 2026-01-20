@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class BreakingNewsCardSnapshotTests: XCTestCase {
    // MARK: - Helper Method

    private func createMockArticle(
        id: String = "breaking-news",
        title: String = "Breaking News: Major Development",
        description: String = "A significant news story developing right now.",
        imageUrl: String? = nil,
        source: String = "The Guardian"
    ) -> Article {
        Article(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            publishedAt: Date(),
            url: "https://example.com/article",
            source: source,
            category: .world,
            content: nil
        )
    }

    // MARK: - Standard Breaking News Card Tests

    func testBreakingNewsCardWithImage() {
        let article = createMockArticle(
            title: "Breaking: Major Event Occurs",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBreakingNewsCardWithoutImage() {
        let article = createMockArticle(
            title: "Breaking: Text Only Update",
            imageUrl: nil
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBreakingNewsCardShortTitle() {
        let article = createMockArticle(
            title: "Breaking News",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBreakingNewsCardLongTitle() {
        let article = createMockArticle(
            title: "Breaking News: This Is An Extremely Long Title That Tests How The Card Component Handles Extended Text Wrapped Across Multiple Lines",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Different Source Tests

    func testBreakingNewsCardBBCSource() {
        let article = createMockArticle(
            title: "BBC Breaking News",
            source: "BBC News",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testBreakingNewsCardDarkMode() {
        let article = createMockArticle(
            title: "Breaking News",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))
            .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBreakingNewsCardLightMode() {
        let article = createMockArticle(
            title: "Breaking News",
            imageUrl: "https://via.placeholder.com/375x200"
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))
            .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Different Category Tests

    func testBreakingNewsCardTechnologyCategory() {
        let article = Article(
            id: "tech-breaking",
            title: "Breaking Tech News",
            description: "Major technology announcement.",
            imageUrl: "https://via.placeholder.com/375x200",
            publishedAt: Date(),
            url: "https://example.com/article",
            source: "Tech Daily",
            category: .technology,
            content: nil
        )

        let view = BreakingNewsCard(article: article, onSelect: {})
            .frame(width: 375, height: 250)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
