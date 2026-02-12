import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class TopicsBreakdownCardSnapshotTests: XCTestCase {
    private let darkConfig = SnapshotConfig.iPhoneAir
    private let lightConfig = SnapshotConfig.iPhoneAirLight

    func testTopicsBreakdownCardDefault() {
        let breakdown: [(NewsCategory, Int)] = [
            (.technology, 3),
            (.business, 2),
            (.world, 1),
        ]

        let view = TopicsBreakdownCard(breakdown: breakdown)
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

    func testTopicsBreakdownCardLightMode() {
        let breakdown: [(NewsCategory, Int)] = [
            (.technology, 3),
            (.business, 2),
            (.world, 1),
        ]

        let view = TopicsBreakdownCard(breakdown: breakdown)
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

    func testTopicsBreakdownCardAllCategories() {
        let breakdown: [(NewsCategory, Int)] = [
            (.technology, 5),
            (.business, 4),
            (.world, 3),
            (.science, 2),
        ]

        let view = TopicsBreakdownCard(breakdown: breakdown)
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

    func testTopicsBreakdownCardSingleTopic() {
        let breakdown: [(NewsCategory, Int)] = [
            (.technology, 5),
        ]

        let view = TopicsBreakdownCard(breakdown: breakdown)
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
