import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class BookmarksViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ServiceLocator.shared.register(BookmarksService.self, service: MockBookmarksService())
        ServiceLocator.shared.register(StorageService.self, service: MockStorageService())
    }

    func testBookmarksViewEmpty() {
        let view = BookmarksView()
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
