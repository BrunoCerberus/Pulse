import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("PlaybackViewModel Tests")
@MainActor
struct PlaybackViewModelTests {
    let mockPlaybackQueueService: MockPlaybackQueueService
    let serviceLocator: ServiceLocator
    let sut: PlaybackViewModel

    init() {
        mockPlaybackQueueService = MockPlaybackQueueService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        sut = PlaybackViewModel(serviceLocator: serviceLocator)
    }

    private func makeItem(id: String = "item-0") -> PlaybackItem {
        PlaybackItem(
            id: id,
            kind: .article(Article.mockArticles[0]),
            title: "Title",
            sourceName: "Source",
            speechText: "Speech",
            language: "en",
        )
    }

    // MARK: - Event → Action Mapping

    @Test("transport events reach the playback queue service")
    func transportEventsReachService() {
        mockPlaybackQueueService.play(items: [makeItem(id: "a"), makeItem(id: "b")], mode: .briefing)

        sut.handle(event: .onPlayPauseTapped)
        #expect(mockPlaybackQueueService.togglePlayPauseCallCount == 1)

        sut.handle(event: .onNextTapped)
        #expect(mockPlaybackQueueService.nextCallCount == 1)

        sut.handle(event: .onPreviousTapped)
        #expect(mockPlaybackQueueService.previousCallCount == 1)

        sut.handle(event: .onSpeedTapped)
        #expect(mockPlaybackQueueService.cycleSpeedCallCount == 1)

        sut.handle(event: .onQueueItemTapped(itemID: "b"))
        #expect(mockPlaybackQueueService.skipCallCount == 1)
        #expect(mockPlaybackQueueService.lastSkippedToItemID == "b")

        sut.handle(event: .onStopTapped)
        #expect(mockPlaybackQueueService.stopCallCount == 1)
    }

    @Test("expand and dismiss events drive the queue sheet flag")
    func queueSheetEvents() async {
        // The sheet only exists alongside an active queue — the interactor
        // force-dismisses it whenever the queue goes inactive.
        mockPlaybackQueueService.play(items: [makeItem()], mode: .singleArticle)
        let visible = await waitForCondition { @MainActor in
            sut.viewState.isVisible
        }
        #expect(visible)

        sut.handle(event: .onExpandTapped)
        let presented = await waitForCondition { @MainActor in
            sut.viewState.isQueueSheetPresented
        }
        #expect(presented)

        sut.handle(event: .onQueueSheetDismissed)
        let dismissed = await waitForCondition { @MainActor in
            !sut.viewState.isQueueSheetPresented
        }
        #expect(dismissed)
    }

    // MARK: - State Reduction

    @Test("active queue state maps into the view state")
    func activeQueueStateMapsToViewState() async {
        var state = PlaybackQueueState.idle
        state.items = [makeItem(id: "digest-1"), makeItem(id: "a")]
        state.currentIndex = 0
        state.mode = .briefing
        state.playbackState = .playing
        state.itemProgress = 0.4
        mockPlaybackQueueService.simulateState(state)

        let visible = await waitForCondition { @MainActor in
            sut.viewState.isVisible
        }
        #expect(visible)
        #expect(sut.viewState.title == "Title")
        #expect(sut.viewState.isPlaying)
        #expect(abs(sut.viewState.itemProgress - 0.4) < 0.001)
        #expect(sut.viewState.hasNext)
        #expect(!sut.viewState.hasPrevious)
        #expect(sut.viewState.queuePositionLabel == "1/2")
        #expect(sut.viewState.queueItems.count == 2)
        #expect(sut.viewState.queueItems[0].isCurrent)
    }

    @Test("inactive queue hides the mini player")
    func inactiveQueueHidesPlayer() async {
        mockPlaybackQueueService.play(items: [makeItem()], mode: .singleArticle)
        let visible = await waitForCondition { @MainActor in
            sut.viewState.isVisible
        }
        #expect(visible)

        mockPlaybackQueueService.stop()
        let hidden = await waitForCondition { @MainActor in
            !sut.viewState.isVisible
        }
        #expect(hidden)
    }
}
