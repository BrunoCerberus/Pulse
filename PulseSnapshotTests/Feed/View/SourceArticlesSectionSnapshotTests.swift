@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SourceArticlesSectionSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date articles for snapshot stability
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
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
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
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
