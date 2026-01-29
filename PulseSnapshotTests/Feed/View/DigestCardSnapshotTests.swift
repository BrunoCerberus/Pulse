import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class DigestCardSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    func testDigestCardDefault() {
        let digest = DigestViewItem(
            from: DailyDigest(
                id: "1",
                summary: "Today's reading focused on technology and business. You explored developments in AI, market trends, and startup news.",
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
            .padding()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testDigestCardLongSummary() {
        let longSummary = """
        Today's reading covered a wide range of topics across technology, business, and science. \
        You explored the latest developments in artificial intelligence, including new large language models \
        and their applications in productivity tools. The business articles covered market trends, \
        startup funding rounds in the tech sector, and analysis of quarterly earnings. \
        Science articles highlighted breakthroughs in quantum computing and climate research.
        """

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "2",
                summary: longSummary,
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
            .padding()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testDigestCardShortSummary() {
        let digest = DigestViewItem(
            from: DailyDigest(
                id: "3",
                summary: "Quick read today. Tech news dominated.",
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
            .padding()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Light Mode Tests

    func testDigestCardDefaultLightMode() {
        let digest = DigestViewItem(
            from: DailyDigest(
                id: "4",
                summary: "Today's reading focused on technology and business. You explored developments in AI, market trends, and startup news.",
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
            .padding()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    func testDigestCardLongSummaryLightMode() {
        let longSummary = """
        Today's reading covered a wide range of topics across technology, business, and science. \
        You explored the latest developments in artificial intelligence, including new large language models \
        and their applications in productivity tools.
        """

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "5",
                summary: longSummary,
                sourceArticles: [],
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
            .padding()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Article Count Variants

    func testDigestCardWithArticleCount() {
        let articles = [
            Article(
                id: "1",
                title: "Article 1",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .technology
            ),
            Article(
                id: "2",
                title: "Article 2",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .business
            ),
            Article(
                id: "3",
                title: "Article 3",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
                category: .science
            ),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "6",
                summary: "Today's reading focused on technology and business.",
                sourceArticles: articles,
                generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
            )
        )

        let view = DigestCard(digest: digest)
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
