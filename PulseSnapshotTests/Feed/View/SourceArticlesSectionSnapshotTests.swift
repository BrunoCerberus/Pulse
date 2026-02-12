import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SourceArticlesSectionSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    /// Fixed date articles for snapshot stability
    private var snapshotArticles: [FeedSourceArticle] {
        [
            FeedSourceArticle(from: Article(
                id: "snapshot-1",
                title: "SwiftUI 6.0 Brings Revolutionary New Features",
                description: "Apple announces major updates",
                content: "Full content...",
                author: "John Appleseed",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .technology
            )),
            FeedSourceArticle(from: Article(
                id: "snapshot-2",
                title: "Global Markets Rally on Economic Data",
                description: "Markets see gains",
                content: "Full content...",
                author: "Jane Doe",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_534_800),
                category: .business
            )),
            FeedSourceArticle(from: Article(
                id: "snapshot-3",
                title: "New Study Reveals Health Benefits of Exercise",
                description: "Research shows positive effects",
                content: "Full content...",
                author: "Dr. Smith",
                source: ArticleSource(id: "bbc", name: "BBC Health"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_538_400),
                category: .health
            )),
        ]
    }

    func testSourceArticlesSectionCollapsed() {
        let view = SourceArticlesSection(
            articles: snapshotArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testSourceArticlesSectionSingleArticle() {
        let view = SourceArticlesSection(
            articles: [snapshotArticles[0]],
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    // MARK: - Light Mode Tests

    func testSourceArticlesSectionCollapsedLightMode() {
        let view = SourceArticlesSection(
            articles: snapshotArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirLightConfig),
            record: false
        )
    }

    // MARK: - Long Title Tests

    func testSourceArticlesSectionLongTitles() {
        let longTitleArticles = [
            FeedSourceArticle(from: Article(
                id: "long-1",
                title: "This Is An Extremely Long Article Title That Should Test How The UI Handles Text Truncation And Line Limits In The Source Article Row",
                description: "Long description here",
                content: "Full content...",
                author: "John Appleseed",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .technology
            )),
            FeedSourceArticle(from: Article(
                id: "long-2",
                title: "Another Very Long Title For Testing Purposes To See How Multiple Long Titles Render Together",
                description: "Description",
                content: "Full content...",
                author: "Jane Doe",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_534_800),
                category: .business
            )),
        ]

        let view = SourceArticlesSection(
            articles: longTitleArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    // MARK: - Many Articles Test

    func testSourceArticlesSectionManyArticles() {
        var manyArticles: [FeedSourceArticle] = []
        for i in 0 ..< 10 {
            manyArticles.append(FeedSourceArticle(from: Article(
                id: "many-\(i)",
                title: "Article \(i + 1): Sample News Headline",
                description: "Description for article \(i + 1)",
                content: "Full content...",
                author: "Author \(i)",
                source: ArticleSource(id: "source-\(i)", name: "Source \(i)"),
                url: "https://example.com/\(i)",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200 + Double(i * 3600)),
                category: NewsCategory.allCases[i % NewsCategory.allCases.count]
            )))
        }

        let view = SourceArticlesSection(
            articles: manyArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
