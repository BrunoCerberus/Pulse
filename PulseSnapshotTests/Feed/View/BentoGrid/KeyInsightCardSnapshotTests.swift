@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class KeyInsightCardSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    private var testArticles: [FeedSourceArticle] {
        [
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
            ),
            FeedSourceArticle(
                from: Article(
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
                )
            ),
        ]
    }

    func testKeyInsightCardDefault() {
        let insight = "Today's reading focused on technology and business developments, with AI advancements taking center stage."

        let view = KeyInsightCard(
            insight: insight,
            relatedArticles: testArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testKeyInsightCardLightMode() {
        let insight = "Today's reading focused on technology and business developments, with AI advancements taking center stage."

        let view = KeyInsightCard(
            insight: insight,
            relatedArticles: testArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: lightConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testKeyInsightCardLongInsight() {
        let longInsight = """
        Today's reading brought us a diverse array of topics, from the complexities of AI chips in China \
        to the mysteries of the universe. The most striking thread throughout this collection is the \
        exploration of human nature and technology's influence on society. The articles shed light on \
        the tensions between innovation and regulation.
        """

        let view = KeyInsightCard(
            insight: longInsight,
            relatedArticles: testArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testKeyInsightCardNoArticles() {
        let insight = "Today's reading focused on technology and business developments."

        let view = KeyInsightCard(
            insight: insight,
            relatedArticles: [],
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testKeyInsightCardShortInsight() {
        let shortInsight = "Quick tech news today."

        let view = KeyInsightCard(
            insight: shortInsight,
            relatedArticles: testArticles,
            onArticleTapped: { _ in }
        )
        .padding()
        .frame(width: 360)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: darkConfig, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
