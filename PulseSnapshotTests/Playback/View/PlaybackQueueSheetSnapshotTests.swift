import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class PlaybackQueueSheetSnapshotTests: XCTestCase {
    private let sheetConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 500),
        traits: UITraitCollection(userInterfaceStyle: .dark),
    )

    private let sheetLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        size: CGSize(width: 393, height: 500),
        traits: UITraitCollection(userInterfaceStyle: .light),
    )

    private func makeBriefingState() -> PlaybackQueueState {
        var items: [PlaybackItem] = [
            PlaybackItem(
                id: "digest-today",
                kind: .digest,
                title: "Today's Digest",
                sourceName: "Pulse",
                speechText: "Digest narration",
                language: "en",
            ),
        ]
        let titles = [
            "SwiftUI 6.0 Brings Revolutionary New Features",
            "Global Markets Rally on Tech Earnings",
            "New Study Reveals Benefits of Sleep",
        ]
        let sources = ["TechCrunch", "Bloomberg", "Science Daily"]
        for index in 0 ..< titles.count {
            items.append(
                PlaybackItem(
                    id: "article-\(index)",
                    kind: .article(Article.mockArticles[index % Article.mockArticles.count]),
                    title: titles[index],
                    sourceName: sources[index],
                    speechText: "Article narration",
                    language: "en",
                ),
            )
        }

        var state = PlaybackQueueState.idle
        state.items = items
        state.currentIndex = 1
        state.mode = .briefing
        state.playbackState = .playing
        state.itemProgress = 0.35
        return state
    }

    private func makeView() -> some View {
        let serviceLocator = ServiceLocator()
        let mockService = MockPlaybackQueueService()
        serviceLocator.register(PlaybackQueueService.self, instance: mockService)

        let viewModel = PlaybackViewModel(serviceLocator: serviceLocator)
        mockService.simulateState(makeBriefingState())
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return PlaybackQueueSheet(viewModel: viewModel)
            .background(Color(.systemBackground))
    }

    func test_queueSheet_dark() {
        let viewController = UIHostingController(rootView: makeView())

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: sheetConfig),
            record: false,
        )
    }

    func test_queueSheet_light() {
        let viewController = UIHostingController(rootView: makeView())

        assertSnapshot(
            of: viewController,
            as: SnapshotConfig.snapshotting(on: sheetLightConfig),
            record: false,
        )
    }
}
