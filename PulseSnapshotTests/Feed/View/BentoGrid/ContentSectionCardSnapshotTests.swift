import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ContentSectionCardSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    private var testArticles: [FeedSourceArticle] {
        [
            FeedSourceArticle(
                from: Article(
                    id: "test-1",
                    title: "AI Chip Developments",
                    description: "Latest in AI hardware",
                    content: nil,
                    author: nil,
                    source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                    url: "https://example.com/1",
                    imageURL: nil,
                    publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                    category: .technology
                )
            ),
            FeedSourceArticle(
                from: Article(
                    id: "test-2",
                    title: "Software Updates",
                    description: "New releases",
                    content: nil,
                    author: nil,
                    source: ArticleSource(id: "verge", name: "The Verge"),
                    url: "https://example.com/2",
                    imageURL: nil,
                    publishedAt: Date(timeIntervalSince1970: 1_672_534_800),
                    category: .technology
                )
            ),
        ]
    }

    func testContentSectionCardWithCategory() {
        let section = DigestSection(
            id: "test-section-1",
            title: "Technology",
            content: "The technology sector saw significant developments with new AI models being announced and companies pivoting their strategies.",
            category: .technology,
            relatedArticles: testArticles
        )

        let view = ContentSectionCard(
            section: section,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testContentSectionCardLightMode() {
        let section = DigestSection(
            id: "test-section-2",
            title: "Technology",
            content: "The technology sector saw significant developments with new AI models being announced.",
            category: .technology,
            relatedArticles: testArticles
        )

        let view = ContentSectionCard(
            section: section,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lightConfig),
            record: false
        )
    }

    func testContentSectionCardBusinessCategory() {
        let section = DigestSection(
            id: "test-section-3",
            title: "Business",
            content: "Business markets responded positively to the tech developments, with stock prices reflecting investor optimism.",
            category: .business,
            relatedArticles: []
        )

        let view = ContentSectionCard(
            section: section,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testContentSectionCardNoCategory() {
        let section = DigestSection(
            id: "test-section-4",
            title: "Deep Dive",
            content: "This section explores various topics without a specific category focus.",
            category: nil,
            relatedArticles: testArticles
        )

        let view = ContentSectionCard(
            section: section,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testContentSectionCardWorldCategory() {
        let section = DigestSection(
            id: "test-section-5",
            title: "World",
            content: "International coverage highlighted diplomatic relations and global economic trends.",
            category: .world,
            relatedArticles: []
        )

        let view = ContentSectionCard(
            section: section,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }
}
