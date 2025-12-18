@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

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
            as: .image(on: .iPhone13Pro, precision: 0.98),
            record: false
        )
    }
}
