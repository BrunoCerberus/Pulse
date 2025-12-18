import XCTest
import SnapshotTesting
import SwiftUI
@testable import Pulse

final class SettingsViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
    }

    func testSettingsViewInitial() {
        let view = SettingsView(serviceLocator: serviceLocator)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
