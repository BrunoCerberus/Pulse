@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ArticleRowViewSnapshotTests: XCTestCase {
    // MARK: - Helper Method

    private func createMockArticle(
        id: String = "test-article",
        title: String = "Test Article Title",
        description: String = "This is a test article description that spans multiple lines to show how the row handles longer text content.",
        imageUrl: String? = nil,
        publishedAt: Date = Date(),
        source: String = "The Guardian"
    ) -> Article {
        Article(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            publishedAt: publishedAt,
            url: "https://example.com/article",
            source: source,
            category: .world,
            content: nil
        )
    }

    // MARK: - Standard Article Row Tests

    func testArticleRowStandardWithImage() {
        let article = createMockArticle(
            title: "Major News Story",
            description: "Breaking news from around the world with significant developments.",
            imageUrl: "https://via.placeholder.com/150"
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testArticleRowWithoutImage() {
        let article = createMockArticle(
            title: "Text Only Story",
            description: "A news article without an image thumbnail.",
            imageUrl: nil
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testArticleRowShortText() {
        let article = createMockArticle(
            title: "Quick News",
            description: "Short description."
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testArticleRowLongTitle() {
        let article = createMockArticle(
            title: "This Is A Very Long Title That Spans Multiple Lines To Test How The Article Row Component Handles Extended Text Content",
            description: "Brief description."
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Different Source Tests

    func testArticleRowDifferentSource() {
        let article = createMockArticle(
            title: "BBC World News",
            source: "BBC News",
            imageUrl: "https://via.placeholder.com/150"
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testArticleRowDarkMode() {
        let article = createMockArticle(
            title: "Dark Mode Article",
            description: "Testing how the article row appears in dark mode.",
            imageUrl: "https://via.placeholder.com/150"
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))
            .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testArticleRowLightMode() {
        let article = createMockArticle(
            title: "Light Mode Article",
            description: "Testing how the article row appears in light mode.",
            imageUrl: "https://via.placeholder.com/150"
        )

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))
            .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Accessibility Tests

    func testArticleRowAccessibility() {
        let article = createMockArticle()

        let view = ArticleRowView(article: article, onSelect: {})
            .frame(width: 375)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
