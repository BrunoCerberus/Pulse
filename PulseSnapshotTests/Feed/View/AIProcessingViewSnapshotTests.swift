import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class AIProcessingViewSnapshotTests: XCTestCase {
    func testAIProcessingViewGenerating() {
        let view = AIProcessingView(
            phase: .generating,
            streamingText: ""
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testAIProcessingViewGeneratingWithStreamingText() {
        let view = AIProcessingView(
            phase: .generating,
            streamingText: "Today's digest covers the latest developments in technology and business. Key highlights include advancements in AI..."
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testAIProcessingViewLightMode() {
        let view = AIProcessingView(
            phase: .generating,
            streamingText: "AI digest content..."
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: SnapshotConfig.iPhoneAirLight, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
