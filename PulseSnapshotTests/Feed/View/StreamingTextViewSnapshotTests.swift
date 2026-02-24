import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class StreamingTextViewSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    func testStreamingTextViewWithContent() {
        let view = StreamingTextView(
            text: "Today's reading focused on technology and business topics. You explored developments in AI and market trends."
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }

    func testStreamingTextViewShortText() {
        let view = StreamingTextView(
            text: "Today's reading focused on technology"
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    func testStreamingTextViewEmpty() {
        let view = StreamingTextView(
            text: ""
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: true
        )
    }

    func testStreamingTextViewLongContent() {
        let longText = """
        Today's reading covered a wide range of topics across technology, business, and science. \
        You explored the latest developments in artificial intelligence, including new large language models \
        and their applications in productivity tools. The business articles covered market trends, \
        startup funding rounds in the tech sector, and analysis of quarterly earnings.
        """

        let view = StreamingTextView(
            text: longText
        )
        .padding()
        .frame(width: 375)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: iPhoneAirConfig),
            record: false
        )
    }
}
