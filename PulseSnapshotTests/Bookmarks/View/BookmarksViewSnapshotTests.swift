import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class BookmarksViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testBookmarksViewEmpty() {
        let view = BookmarksView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
