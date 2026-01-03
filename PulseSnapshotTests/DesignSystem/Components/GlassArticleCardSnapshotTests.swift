@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassArticleCardSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date article for snapshot stability (Jan 1, 2023 - will always show consistent relative time)
    private var snapshotArticle: Article {
        Article(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features for iOS Development",
            description: "Apple announces major updates to SwiftUI at WWDC 2024, including improved performance and new APIs",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200), // Jan 1, 2023 00:00:00 UTC
            category: .technology
        )
    }

    private var articleWithoutDescription: Article {
        Article(
            id: "snapshot-2",
            title: "Breaking: Major Climate Agreement Reached at Global Summit",
            description: nil,
            content: "Full article content here...",
            author: "Jane Doe",
            source: ArticleSource(id: "reuters", name: "Reuters"),
            url: "https://example.com/2",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
            category: .world
        )
    }

    private var articleWithoutImage: Article {
        Article(
            id: "snapshot-3",
            title: "New Study Reveals Health Benefits of Mediterranean Diet",
            description: "Researchers find significant improvements in cardiovascular health",
            content: "Full article content here...",
            author: "Dr. Smith",
            source: ArticleSource(id: "bbc", name: "BBC Health"),
            url: "https://example.com/3",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
            category: .health
        )
    }

    // MARK: - GlassArticleCard Tests

    func testGlassArticleCardWithAllContent() {
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testGlassArticleCardBookmarked() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = GlassArticleCard(
            item: item,
            isBookmarked: true,
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testGlassArticleCardWithoutDescription() {
        let item = ArticleViewItem(from: articleWithoutDescription)
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testGlassArticleCardWithoutImage() {
        let item = ArticleViewItem(from: articleWithoutImage)
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testGlassArticleCardAllCategories() {
        let categories: [NewsCategory] = [.business, .entertainment, .science, .sports]

        for category in categories {
            let article = Article(
                id: "cat-\(category.rawValue)",
                title: "Article about \(category.displayName)",
                description: "Description for \(category.displayName) category",
                source: ArticleSource(id: nil, name: "Test Source"),
                url: "https://example.com",
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: category
            )
            let item = ArticleViewItem(from: article)
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
                as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
                record: false,
                testName: "testGlassArticleCard_\(category.rawValue)"
            )
        }
    }

    // MARK: - GlassArticleCardCompact Tests

    func testGlassArticleCardCompactWithImage() {
        let view = GlassArticleCardCompact(
            title: "Quick Update on Markets Today",
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testGlassArticleCardCompactWithoutImage() {
        let view = GlassArticleCardCompact(
            title: "Quick Update on Markets Today",
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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }
}
