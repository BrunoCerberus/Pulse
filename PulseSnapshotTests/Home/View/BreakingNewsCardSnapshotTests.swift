@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class BreakingNewsCardSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var breakingArticleViewItem: ArticleViewItem {
        ArticleViewItem(from: Article(
            id: "breaking-1",
            title: "Breaking: Major Tech Announcement at WWDC 2024",
            description: "Apple announces groundbreaking new features.",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/breaking",
            imageURL: "https://picsum.photos/300/200",
            publishedAt: fixedDate,
            category: .technology
        ))
    }

    private var longTitleBreakingArticleViewItem: ArticleViewItem {
        ArticleViewItem(from: Article(
            id: "breaking-long",
            title: "Breaking News With An Exceptionally Long Title That Should Test The Text Truncation And Layout Of This Component",
            source: ArticleSource(id: "reuters", name: "Reuters"),
            url: "https://example.com/long",
            imageURL: nil,
            publishedAt: fixedDate,
            category: .world
        ))
    }

    func testBreakingNewsCardStandard() {
        let view = BreakingNewsCard(
            item: breakingArticleViewItem,
            onTap: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testBreakingNewsCardLongTitle() {
        let view = BreakingNewsCard(
            item: longTitleBreakingArticleViewItem,
            onTap: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }
}
