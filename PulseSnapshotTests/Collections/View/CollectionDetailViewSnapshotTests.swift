import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class CollectionDetailViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(CollectionsService.self, instance: MockCollectionsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    // MARK: - Collection Detail Tests

    func testCollectionDetailViewWithProgress() {
        let articles = createSampleArticles()
        let collection = Collection(
            id: "climate-crisis",
            name: "Climate Crisis",
            description: "Understand the science, politics, and solutions to our planet's greatest challenge",
            imageURL: nil,
            articles: articles,
            articleIDs: Set(articles.map(\.id)),
            readArticleIDs: ["article-1", "article-2"],
            collectionType: .featured,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )

        let view = NavigationStack {
            CollectionDetailView(
                collection: collection,
                router: CollectionsNavigationRouter(),
                serviceLocator: serviceLocator
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionDetailViewCompleted() {
        let articles = createSampleArticles()
        let collection = Collection(
            id: "completed-collection",
            name: "Global Politics",
            description: "World affairs explained in depth",
            imageURL: nil,
            articles: articles,
            articleIDs: Set(articles.map(\.id)),
            readArticleIDs: Set(articles.map(\.id)),
            collectionType: .featured,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )

        let view = NavigationStack {
            CollectionDetailView(
                collection: collection,
                router: CollectionsNavigationRouter(),
                serviceLocator: serviceLocator
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionDetailViewNoProgress() {
        let articles = createSampleArticles()
        let collection = Collection(
            id: "no-progress",
            name: "AI & Technology",
            description: "Latest developments in artificial intelligence and tech",
            imageURL: nil,
            articles: articles,
            articleIDs: Set(articles.map(\.id)),
            readArticleIDs: [],
            collectionType: .featured,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )

        let view = NavigationStack {
            CollectionDetailView(
                collection: collection,
                router: CollectionsNavigationRouter(),
                serviceLocator: serviceLocator
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionDetailViewPremium() {
        let articles = createSampleArticles()
        let collection = Collection(
            id: "premium-collection",
            name: "Premium Insights",
            description: "Exclusive curated content for premium members",
            imageURL: nil,
            articles: articles,
            articleIDs: Set(articles.map(\.id)),
            readArticleIDs: ["article-1"],
            collectionType: .aiCurated,
            isPremium: true,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )

        let view = NavigationStack {
            CollectionDetailView(
                collection: collection,
                router: CollectionsNavigationRouter(),
                serviceLocator: serviceLocator
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCollectionDetailViewUserCollection() {
        let articles = createSampleArticles()
        let collection = Collection(
            id: "user-collection",
            name: "My Research",
            description: "Articles saved for my research project",
            imageURL: nil,
            articles: articles,
            articleIDs: Set(articles.map(\.id)),
            readArticleIDs: ["article-1", "article-2", "article-3"],
            collectionType: .user,
            isPremium: false,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )

        let view = NavigationStack {
            CollectionDetailView(
                collection: collection,
                router: CollectionsNavigationRouter(),
                serviceLocator: serviceLocator
            )
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Helper Methods

    private func createSampleArticles() -> [Article] {
        [
            Article(
                id: "article-1",
                title: "Understanding Climate Change: The Science Behind Global Warming",
                description: "A comprehensive look at the scientific evidence for climate change",
                content: "Full article content here",
                author: "Dr. Jane Smith",
                source: ArticleSource(id: "guardian", name: "The Guardian"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .science
            ),
            Article(
                id: "article-2",
                title: "The Paris Agreement Explained: What World Leaders Committed To",
                description: "Breaking down the key commitments of the Paris Climate Agreement",
                content: "Full article content here",
                author: "John Doe",
                source: ArticleSource(id: "bbc", name: "BBC News"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: fixedDate.addingTimeInterval(-86400),
                category: .world
            ),
            Article(
                id: "article-3",
                title: "Renewable Energy Solutions: Solar and Wind Power Advances",
                description: "Latest developments in renewable energy technology",
                content: "Full article content here",
                author: "Sarah Johnson",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: fixedDate.addingTimeInterval(-172_800),
                category: .technology
            ),
            Article(
                id: "article-4",
                title: "How Individuals Can Combat Climate Change",
                description: "Practical steps everyone can take to reduce their carbon footprint",
                content: "Full article content here",
                author: "Mike Brown",
                source: ArticleSource(id: "nyt", name: "New York Times"),
                url: "https://example.com/4",
                imageURL: nil,
                publishedAt: fixedDate.addingTimeInterval(-259_200),
                category: .entertainment
            ),
            Article(
                id: "article-5",
                title: "The Economic Impact of Climate Policies",
                description: "Analyzing the economic implications of climate action",
                content: "Full article content here",
                author: "Emily Chen",
                source: ArticleSource(id: "economist", name: "The Economist"),
                url: "https://example.com/5",
                imageURL: nil,
                publishedAt: fixedDate.addingTimeInterval(-345_600),
                category: .business
            ),
        ]
    }
}
