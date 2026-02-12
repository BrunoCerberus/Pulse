import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class FeedEmptyStateViewSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    func testFeedEmptyStateDefault() {
        let view = FeedEmptyStateView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
