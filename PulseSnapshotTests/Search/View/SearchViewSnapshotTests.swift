import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class SearchViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ServiceLocator.shared.register(SearchService.self, service: MockSearchService())
        ServiceLocator.shared.register(StorageService.self, service: MockStorageService())
    }

    func testSearchViewInitial() {
        let view = SearchView()
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
