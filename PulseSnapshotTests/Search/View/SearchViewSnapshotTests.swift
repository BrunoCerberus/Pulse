@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SearchViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection()
    )

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
    }

    func testSearchViewInitial() {
        let view = SearchView(
            router: SearchNavigationRouter(),
            viewModel: SearchViewModel(serviceLocator: serviceLocator)
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.95)),
            record: false
        )
    }
}
