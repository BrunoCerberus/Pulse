@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

final class HomeViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testHomeViewLoading() {
        let view = HomeView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }

    func testArticleRowView() {
        let item = ArticleViewItem(from: Article.mockArticles[0])
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
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }

    func testBreakingNewsCard() {
        let item = ArticleViewItem(from: Article.mockArticles[0])
        let view = BreakingNewsCard(item: item, onTap: {})
            .padding()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }

    func testArticleSkeletonView() {
        let view = ArticleSkeletonView()
            .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
