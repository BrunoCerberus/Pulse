import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class FeedViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!
    private var mockFeedService: MockFeedService!
    private var mockStorageService: MockStorageService!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date article for snapshot stability
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
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(FeedService.self, instance: mockFeedService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

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
        mockStorageService.readingHistory = []
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
        let digest = DailyDigest(
            id: "test",
            summary: "Today's reading focused on technology and business topics. You explored developments in AI and market trends.",
            sourceArticles: snapshotArticles,
            generatedAt: Date(timeIntervalSince1970: 1_672_531_200)
        )
        mockFeedService.cachedDigest = digest
        mockStorageService.readingHistory = snapshotArticles

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
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
