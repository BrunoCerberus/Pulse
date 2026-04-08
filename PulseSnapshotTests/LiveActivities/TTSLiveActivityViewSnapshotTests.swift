import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class TTSLiveActivityViewSnapshotTests: XCTestCase {
    private let lockScreenConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 160),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private func makeView(
        isPlaying: Bool = true,
        progress: Double = 0.35,
        speedLabel: String = "1x",
        articleTitle: String = "SwiftUI 6.0 Brings Revolutionary New Features",
        sourceName: String = "TechCrunch"
    ) -> some View {
        TTSLockScreenView(
            state: .init(
                isPlaying: isPlaying,
                progress: progress,
                speedLabel: speedLabel
            ),
            articleTitle: articleTitle,
            sourceName: sourceName
        )
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    func test_playing_normal_speed() {
        let view = makeView()
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lockScreenConfig),
            record: false
        )
    }

    func test_paused_high_progress() {
        let view = makeView(isPlaying: false, progress: 0.7)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lockScreenConfig),
            record: false
        )
    }

    func test_long_title_truncation() {
        let view = makeView(
            progress: 0.5,
            articleTitle: "This Is An Extremely Long Article Title That Should "
                + "Test How The Live Activity Lock Screen View Handles Text "
                + "Truncation When Rendered At The Standard Width"
        )
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lockScreenConfig),
            record: false
        )
    }

    func test_fastest_speed_preset() {
        let view = makeView(progress: 0.85, speedLabel: "2x")
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: lockScreenConfig),
            record: false
        )
    }
}
