import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class StatsCardSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    func testStatsCardDefault() {
        let view = StatsCard(articleCount: 5, topicsCount: 3)
            .padding()
            .frame(width: 180)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testStatsCardLightMode() {
        let view = StatsCard(articleCount: 5, topicsCount: 3)
            .padding()
            .frame(width: 180)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lightConfig),
            record: false
        )
    }

    func testStatsCardHighCounts() {
        let view = StatsCard(articleCount: 25, topicsCount: 7)
            .padding()
            .frame(width: 180)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }

    func testStatsCardMinimal() {
        let view = StatsCard(articleCount: 1, topicsCount: 1)
            .padding()
            .frame(width: 180)
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: darkConfig),
            record: false
        )
    }
}
