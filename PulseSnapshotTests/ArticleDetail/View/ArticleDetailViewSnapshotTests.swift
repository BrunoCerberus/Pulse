import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class ArticleDetailViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ServiceLocator.shared.register(StorageService.self, service: MockStorageService())
    }

    func testArticleDetailView() {
        let article = Article.mockArticles[0]
        let view = NavigationStack {
            ArticleDetailView(article: article)
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
