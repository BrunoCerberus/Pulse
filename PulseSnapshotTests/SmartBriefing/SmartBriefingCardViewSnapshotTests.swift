import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SmartBriefingCardViewSnapshotTests: XCTestCase {
    func testSmartBriefingCardFreshState() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: nil,
                statusMessage: nil
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    func testSmartBriefingCardRecentlyServedState() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: false,
                lastServedAt: Date(timeIntervalSince1970: 1_700_000_000).addingTimeInterval(-3 * 3600),
                statusMessage: nil
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    func testSmartBriefingCardBuildingState() {
        let view = SmartBriefingCardView(
            viewState: SmartBriefingViewState(
                isVisible: true,
                isBuilding: true,
                lastServedAt: nil,
                statusMessage: nil
            ),
            onBuildBriefingTapped: {},
            onStartFreshTapped: {}
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }
}
