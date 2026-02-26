import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SpeechPlayerBarViewSnapshotTests: XCTestCase {
    private let compactConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 120),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private let compactLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 120),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    private let compactAccessibilityConfig: ViewImageConfig = {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
        ])
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            size: CGSize(width: 393, height: 160),
            traits: traits
        )
    }()

    private let compactExtraExtraLargeConfig: ViewImageConfig = {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(preferredContentSizeCategory: .extraExtraLarge),
        ])
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            size: CGSize(width: 393, height: 140),
            traits: traits
        )
    }()

    private func makeView(
        title: String = "SwiftUI 6.0 Brings Revolutionary New Features",
        playbackState: TTSPlaybackState = .playing,
        progress: Double = 0.35,
        speedPreset: TTSSpeedPreset = .normal
    ) -> some View {
        SpeechPlayerBarView(
            title: title,
            playbackState: playbackState,
            progress: progress,
            speedPreset: speedPreset,
            onPlayPause: {},
            onStop: {},
            onSpeedTap: {}
        )
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    func test_playing_dark() {
        let view = makeView()
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    func test_playing_light() {
        let view = makeView()
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactLightConfig),
            record: false
        )
    }

    func test_paused() {
        let view = makeView(playbackState: .paused, progress: 0.6)
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    func test_fast_speed() {
        let view = makeView(progress: 0.2, speedPreset: .fast)
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    func test_fastest_speed() {
        let view = makeView(progress: 0.8, speedPreset: .fastest)
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    func test_long_title() {
        let view = makeView(
            title: "This Is An Extremely Long Article Title That Should Test How The UI Handles Text Truncation In The Speech Player Bar",
            progress: 0.5
        )
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    // MARK: - Missing Speed Preset (Gap 10)

    func test_faster_speed() {
        let view = makeView(progress: 0.5, speedPreset: .faster)
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false
        )
    }

    // MARK: - Accessibility Sizes (Gap 11)

    func test_playing_accessibility_size() {
        let view = makeView()
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactAccessibilityConfig),
            record: false
        )
    }

    func test_playing_extra_extra_large_size() {
        let view = makeView()
        let vc = UIHostingController(rootView: view)

        assertSnapshot(
            of: vc,
            as: SnapshotConfig.snapshotting(on: compactExtraExtraLargeConfig),
            record: false
        )
    }
}
