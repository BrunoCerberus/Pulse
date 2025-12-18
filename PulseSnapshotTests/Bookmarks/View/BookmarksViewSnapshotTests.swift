@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

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
            as: .image(on: .iPhone13Pro, precision: 0.98),
            record: false
        )
    }
}
