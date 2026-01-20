@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ArticleRowViewSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var standardArticleViewItem: ArticleViewItem {
        ArticleViewItem(from: Article(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            description: "Apple announces major updates to SwiftUI at WWDC 2024",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: "https://picsum.photos/200",
            publishedAt: fixedDate,
            category: .technology
        ))
    }

    private var longTitleArticleViewItem: ArticleViewItem {
        ArticleViewItem(from: Article(
            id: "snapshot-long",
            title: "This Is An Extremely Long Article Title That Should Test How The UI Handles Text Truncation And Line Limits In The Article Row View Component",
            description: "A brief description that accompanies this article with the very long title.",
            source: ArticleSource(id: "reuters", name: "Reuters"),
            url: "https://example.com/2",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .business
        ))
    }

    private var noImageArticleViewItem: ArticleViewItem {
        ArticleViewItem(from: Article(
            id: "snapshot-no-image",
            title: "Article Without Image",
            description: "This article has no image URL to test how the layout handles missing images.",
            source: ArticleSource(id: "bbc", name: "BBC News"),
            url: "https://example.com/3",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .world
        ))
    }

    func testArticleRowViewStandard() {
        let view = ArticleRowView(
            item: standardArticleViewItem,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testArticleRowViewLongTitle() {
        let view = ArticleRowView(
            item: longTitleArticleViewItem,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testArticleRowViewNoImage() {
        let view = ArticleRowView(
            item: noImageArticleViewItem,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }
}
