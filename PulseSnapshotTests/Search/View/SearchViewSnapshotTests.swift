import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class SearchViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testSearchViewInitial() {
        let view = SearchView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
