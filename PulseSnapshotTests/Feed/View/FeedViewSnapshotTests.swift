import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class FeedViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!
    private var mockFeedService: MockFeedService!
    private var mockNewsService: MockNewsService!

    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// Fixed date article for snapshot stability
    private var snapshotArticle: Article {
        Article(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            description: "Apple announces major updates to SwiftUI at WWDC 2024",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200),
            category: .technology
        )
    }

    private var snapshotArticles: [Article] {
        [
            snapshotArticle,
            Article(
                id: "snapshot-2",
                title: "Global Markets Rally on Economic Data",
                description: "Stock markets see gains across major indices",
                content: "Full article content here...",
                author: "Jane Doe",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: Date(timeIntervalSince1970: 1_672_534_800),
                category: .business
            ),
        ]
    }

    override func setUp() {
        super.setUp()
        mockFeedService = MockFeedService()
        mockNewsService = MockNewsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(NewsService.self, instance: mockNewsService)

        // Register StoreKitService with premium enabled for testing
        let mockStoreKitService = MockStoreKitService(isPremium: true)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)
    }

    func testFeedViewLoading() {
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let view = FeedView(
            router: FeedNavigationRouter(),
            viewModel: viewModel,
            serviceLocator: serviceLocator
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testFeedViewEmpty() {
        mockNewsService.topHeadlinesResult = .success([])
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)

        // Trigger load to show empty state
        viewModel.handle(event: .onAppear)

        let view = FeedView(
            router: FeedNavigationRouter(),
            viewModel: viewModel,
            serviceLocator: serviceLocator
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testFeedViewCompleted() {
        // Multi-paragraph summary to trigger Bento Grid sections
        let summary = """
        Today's reading focused on technology and business topics. You explored developments in AI and market trends.

        The technology sector saw significant movement with new product launches and strategic partnerships being announced.

        Business markets responded positively, with stock prices reflecting investor optimism about AI-driven products.
        """

        let digest = DailyDigest(
            id: "test",
            summary: summary,
            sourceArticles: snapshotArticles,
            generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
        )
        mockFeedService.cachedDigest = digest
        mockNewsService.topHeadlinesResult = .success(snapshotArticles)

        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onAppear)

        let view = FeedView(
            router: FeedNavigationRouter(),
            viewModel: viewModel,
            serviceLocator: serviceLocator
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testFeedViewCompletedSingleParagraph() {
        // Single paragraph - shows only Key Insight + Stats/Topics
        let digest = DailyDigest(
            id: "test-single",
            summary: "Today's reading focused on technology and business topics. You explored developments in AI and market trends.",
            sourceArticles: snapshotArticles,
            generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
        )
        mockFeedService.cachedDigest = digest
        mockNewsService.topHeadlinesResult = .success(snapshotArticles)

        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onAppear)

        let view = FeedView(
            router: FeedNavigationRouter(),
            viewModel: viewModel,
            serviceLocator: serviceLocator
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
