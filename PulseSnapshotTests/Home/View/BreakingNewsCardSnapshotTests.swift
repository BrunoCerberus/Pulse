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

    private var breakingArticleViewItem: ArticleViewItem {
        ArticleViewItem(
            id: "breaking-1",
            title: "Breaking: Major Tech Announcement at WWDC 2024",
            description: "Apple announces groundbreaking new features.",
            sourceName: "TechCrunch",
            imageURL: nil,
            formattedDate: "Jan 1, 2023",
            category: .technology,
            animationIndex: 0
        )
    }

    private var longTitleBreakingArticleViewItem: ArticleViewItem {
        ArticleViewItem(
            id: "breaking-long",
            title: "Breaking News With An Exceptionally Long Title That Should Test The Text Truncation And Layout Of This Component",
            description: "",
            sourceName: "Reuters",
            imageURL: nil,
            formattedDate: "Jan 1, 2023",
            category: .world,
            animationIndex: 0
        )
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
