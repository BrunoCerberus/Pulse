@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class HeroNewsCardSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023 00:00:00 UTC

    private var articleWithImage: ArticleViewItem {
        ArticleViewItem(
            from: Article(
                id: "hero-1",
                title: "Breaking: Major Climate Summit Reaches Historic Agreement on Emissions",
                description: "World leaders commit to ambitious targets",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/400/300",
                publishedAt: fixedDate,
                category: .world
            )
        )
    }

    private var articleWithoutImage: ArticleViewItem {
        ArticleViewItem(
            from: Article(
                id: "hero-2",
                title: "Tech Giants Face New Regulations Across European Union",
                description: "Sweeping changes to digital markets",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            )
        )
    }

    private var articleWithLongTitle: ArticleViewItem {
        ArticleViewItem(
            from: Article(
                id: "hero-3",
                title: "Scientists Make Unprecedented Discovery in Deep Ocean That Could Change Our Understanding of Marine Ecosystems Forever",
                description: "New species found at record depths",
                source: ArticleSource(id: "nature", name: "Nature"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/400/301",
                publishedAt: fixedDate,
                category: .science
            )
        )
    }

    // MARK: - HeroNewsCard Tests

    func testHeroNewsCardWithImage() {
        let view = HeroNewsCard(item: articleWithImage, onTap: {})
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    func testHeroNewsCardWithoutImage() {
        let view = HeroNewsCard(item: articleWithoutImage, onTap: {})
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    func testHeroNewsCardWithLongTitle() {
        let view = HeroNewsCard(item: articleWithLongTitle, onTap: {})
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    // MARK: - FeaturedArticleCard Tests

    func testFeaturedArticleCardWithImage() {
        let view = FeaturedArticleCard(item: articleWithImage, onTap: {})
            .frame(width: 350)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    func testFeaturedArticleCardWithoutImage() {
        let view = FeaturedArticleCard(item: articleWithoutImage, onTap: {})
            .frame(width: 350)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }

    // MARK: - Carousel Test

    func testHeroCarouselLayout() {
        let items = [articleWithImage, articleWithoutImage, articleWithLongTitle]

        let view = ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items, id: \.id) { item in
                    HeroNewsCard(item: item, onTap: {})
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 220)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }
}
