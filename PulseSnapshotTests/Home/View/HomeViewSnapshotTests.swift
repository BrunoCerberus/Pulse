@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class HomeViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection()
    )

    // Fixed date article for snapshot stability (Jan 1, 2023 - will always show consistent relative time)
    private var snapshotArticle: Article {
        Article(
            id: "snapshot-1",
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            description: "Apple announces major updates to SwiftUI at WWDC 2024",
            content: "Full article content here...",
            author: "John Appleseed",
            source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
            url: "https://example.com/1",
            imageURL: "https://picsum.photos/400/300",
            publishedAt: Date(timeIntervalSince1970: 1_672_531_200), // Jan 1, 2023 00:00:00 UTC
            category: .technology
        )
    }

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testHomeViewLoading() {
        let view = HomeView(
            router: HomeNavigationRouter(),
            viewModel: HomeViewModel(serviceLocator: serviceLocator)
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testArticleRowView() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = ArticleRowView(
            item: item,
            onTap: {},
            onBookmark: {},
            onShare: {}
        )
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testBreakingNewsCard() {
        let item = ArticleViewItem(from: snapshotArticle)
        let view = BreakingNewsCard(item: item, onTap: {})
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }

    func testArticleSkeletonView() {
        let view = ArticleSkeletonView()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.98)),
            record: false
        )
    }
}
