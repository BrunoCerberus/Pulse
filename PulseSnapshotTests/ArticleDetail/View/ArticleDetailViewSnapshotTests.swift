@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

final class ArticleDetailViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testArticleDetailView() {
        let article = Article.mockArticles[0]
        let view = NavigationStack {
            ArticleDetailView(article: article, serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
