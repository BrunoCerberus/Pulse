import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class MiniPlayerViewSnapshotTests: XCTestCase {
    private let compactConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 120),
        traits: UITraitCollection(userInterfaceStyle: .dark),
    )

    private let compactLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 120),
        traits: UITraitCollection(userInterfaceStyle: .light),
    )

    private let compactAccessibilityConfig: ViewImageConfig = {
        let traits = UITraitCollection { mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
            mutableTraits.preferredContentSizeCategory = .accessibilityExtraLarge
        }
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            size: CGSize(width: 393, height: 180),
            traits: traits,
        )
    }()

    private func makeItems(count: Int, includeDigest: Bool = false) -> [PlaybackItem] {
        var items: [PlaybackItem] = []
        if includeDigest {
            items.append(
                PlaybackItem(
                    id: "digest-today",
                    kind: .digest,
                    title: "Today's Digest",
                    sourceName: "Pulse",
                    speechText: "Digest narration",
                    language: "en",
                ),
            )
        }
        for index in 0 ..< count {
            items.append(
                PlaybackItem(
                    id: "article-\(index)",
                    kind: .article(Article.mockArticles[index % Article.mockArticles.count]),
                    title: "SwiftUI 6.0 Brings Revolutionary New Features to Apple Platforms",
                    sourceName: "TechCrunch",
                    speechText: "Article narration",
                    language: "en",
                ),
            )
        }
        return items
    }

    /// Builds a view model wired to a mock queue service, pushes the given
    /// state, and pumps the run loop so the Combine pipeline delivers it.
    private func makeViewModel(state: PlaybackQueueState) -> PlaybackViewModel {
        let serviceLocator = ServiceLocator()
        let mockService = MockPlaybackQueueService()
        serviceLocator.register(PlaybackQueueService.self, instance: mockService)

        let viewModel = PlaybackViewModel(serviceLocator: serviceLocator)
        mockService.simulateState(state)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return viewModel
    }

    private func makeView(state: PlaybackQueueState) -> some View {
        MiniPlayerView(viewModel: makeViewModel(state: state))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
    }

    private func makeBriefingState(playing: Bool = true) -> PlaybackQueueState {
        var state = PlaybackQueueState.idle
        state.items = makeItems(count: 3, includeDigest: true)
        state.currentIndex = 1
        state.mode = .briefing
        state.playbackState = playing ? .playing : .paused
        state.itemProgress = 0.35
        return state
    }

    private func makeSingleArticleState() -> PlaybackQueueState {
        var state = PlaybackQueueState.idle
        state.items = makeItems(count: 1)
        state.currentIndex = 0
        state.mode = .singleArticle
        state.playbackState = .playing
        state.itemProgress = 0.35
        return state
    }

    func test_briefing_playing_dark() {
        let viewController = UIHostingController(rootView: makeView(state: makeBriefingState()))

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false,
        )
    }

    func test_briefing_playing_light() {
        let viewController = UIHostingController(rootView: makeView(state: makeBriefingState()))

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: compactLightConfig),
            record: false,
        )
    }

    func test_briefing_paused_dark() {
        let viewController = UIHostingController(rootView: makeView(state: makeBriefingState(playing: false)))

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false,
        )
    }

    func test_singleArticle_playing_dark() {
        let viewController = UIHostingController(rootView: makeView(state: makeSingleArticleState()))

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: compactConfig),
            record: false,
        )
    }

    func test_briefing_playing_accessibility() {
        let viewController = UIHostingController(rootView: makeView(state: makeBriefingState()))

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: compactAccessibilityConfig),
            record: false,
        )
    }
}
