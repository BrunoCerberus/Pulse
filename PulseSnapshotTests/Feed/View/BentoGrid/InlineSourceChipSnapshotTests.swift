import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class InlineSourceChipSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    private var testArticle: FeedSourceArticle {
        FeedSourceArticle(
            from: Article(
                id: "test-1",
                title: "SwiftUI 6.0 Brings Revolutionary Features",
                description: "Apple announces updates",
                content: nil,
                author: "John Appleseed",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .technology
            )
        )
    }

    func testInlineSourceChipDefault() {
        let view = InlineSourceChip(
            article: testArticle,
            onTap: {}
        )
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testInlineSourceChipLightMode() {
        let view = InlineSourceChip(
            article: testArticle,
            onTap: {}
        )
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lightConfig),
            record: false
        )
    }

    func testInlineSourceChipLongTitle() {
        let article = FeedSourceArticle(
            from: Article(
                id: "test-2",
                title: "This is a very long article title that should be truncated to fit within the chip",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: "source", name: "Source"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .business
            )
        )

        let view = InlineSourceChip(
            article: article,
            onTap: {}
        )
        .padding()
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }
}
