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

    private var standardArticleViewItem: ArticleViewItem {
        ArticleViewItem(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            description: "Apple announces major updates to SwiftUI at WWDC 2024",
            sourceName: "TechCrunch",
            imageURL: nil,
            formattedDate: "Jan 1, 2023",
            category: .technology,
            animationIndex: 0
        )
    }

    private var longTitleArticleViewItem: ArticleViewItem {
        ArticleViewItem(
            id: "snapshot-long",
            title: "This Is An Extremely Long Article Title That Should Test How The UI Handles Text Truncation And Line Limits In The Article Row View Component",
            description: "A brief description that accompanies this article with very long title.",
            sourceName: "Reuters",
            imageURL: nil,
            formattedDate: "Jan 1, 2023",
            category: .business,
            animationIndex: 0
        )
    }

    private var noImageArticleViewItem: ArticleViewItem {
        ArticleViewItem(
            id: "snapshot-no-image",
            title: "Article Without Image",
            description: "This article has no image URL to test how the layout handles missing images.",
            sourceName: "BBC News",
            imageURL: nil,
            formattedDate: "Jan 1, 2023",
            category: .world,
            animationIndex: 0
        )
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
