import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class HomeViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Register mock services
        ServiceLocator.shared.register(NewsService.self, service: MockNewsService())
        ServiceLocator.shared.register(StorageService.self, service: MockStorageService())
    }

    func testHomeViewLoading() {
        let view = HomeView()
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
