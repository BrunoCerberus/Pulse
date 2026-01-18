@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class BentoDigestGridSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    private var testArticles: [Article] {
        [
            Article(
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
            ),
            Article(
                id: "test-2",
                title: "Global Markets Rally on Economic Data",
                description: "Markets see gains",
                content: nil,
                author: "Jane Doe",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_534_800),
                category: .business
            ),
            Article(
                id: "test-3",
                title: "Climate Summit Reaches Historic Agreement",
                description: "World leaders agree",
                content: nil,
                author: nil,
                source: ArticleSource(id: "bbc", name: "BBC News"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_538_400),
                category: .world
            ),
        ]
    }

    private var testSourceArticles: [FeedSourceArticle] {
        testArticles.map { FeedSourceArticle(from: $0) }
    }

    func testBentoDigestGridDefault() {
        let summary = """
        Today's reading focused on technology and business developments. AI advancements dominated the tech news.

        The technology sector saw significant movement with new product launches and strategic partnerships.

        Business markets responded positively to the tech developments, with stock prices reflecting investor optimism.
        """

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test-digest",
                summary: summary,
                sourceArticles: testArticles,
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = ScrollView {
            BentoDigestGrid(
                digest: digest,
                sourceArticles: testSourceArticles,
                onArticleTapped: { _ in }
            )
            .padding()
        }
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBentoDigestGridLightMode() {
        let summary = """
        Today's reading focused on technology and business developments. AI advancements dominated the tech news.

        The technology sector saw significant movement with new product launches.
        """

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test-digest-light",
                summary: summary,
                sourceArticles: testArticles,
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = ScrollView {
            BentoDigestGrid(
                digest: digest,
                sourceArticles: testSourceArticles,
                onArticleTapped: { _ in }
            )
            .padding()
        }
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: lightConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBentoDigestGridSingleParagraph() {
        let summary = "Today's reading focused on technology and business developments. AI advancements dominated the tech news with several major announcements."

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test-digest-single",
                summary: summary,
                sourceArticles: testArticles,
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = ScrollView {
            BentoDigestGrid(
                digest: digest,
                sourceArticles: testSourceArticles,
                onArticleTapped: { _ in }
            )
            .padding()
        }
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testBentoDigestGridNoSourceArticles() {
        let summary = """
        Today's reading focused on technology developments.

        The technology sector saw significant movement with new product launches.
        """

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test-digest-no-sources",
                summary: summary,
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = ScrollView {
            BentoDigestGrid(
                digest: digest,
                sourceArticles: [],
                onArticleTapped: { _ in }
            )
            .padding()
        }
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
