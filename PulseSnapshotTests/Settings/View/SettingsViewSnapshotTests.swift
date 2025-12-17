import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class SettingsViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ServiceLocator.shared.register(SettingsService.self, service: MockSettingsService())
    }

    func testSettingsViewInitial() {
        let view = SettingsView()
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
