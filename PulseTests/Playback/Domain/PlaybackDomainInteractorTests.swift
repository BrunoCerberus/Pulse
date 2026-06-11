import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("PlaybackDomainInteractor Tests")
@MainActor
struct PlaybackDomainInteractorTests {
    let mockPlaybackQueueService: MockPlaybackQueueService
    let serviceLocator: ServiceLocator
    let sut: PlaybackDomainInteractor

    init() {
        mockPlaybackQueueService = MockPlaybackQueueService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        sut = PlaybackDomainInteractor(serviceLocator: serviceLocator)
    }

    private func makeActiveState() -> PlaybackQueueState {
        var state = PlaybackQueueState.idle
        state.items = [
            PlaybackItem(
                id: "item-0",
                kind: .article(Article.mockArticles[0]),
                title: "Title",
                sourceName: "Source",
                speechText: "Text",
                language: "en"
            ),
        ]
        state.currentIndex = 0
        state.playbackState = .playing
        return state
    }

    @Test("initial state is inactive")
    func initialState() {
        #expect(sut.currentState.queueState.currentIndex == nil)
        #expect(sut.currentState.isQueueSheetPresented == false)
    }

    @Test("queue service state changes are mirrored into domain state")
    func mirrorsQueueState() async throws {
        mockPlaybackQueueService.simulateState(makeActiveState())
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.queueState.currentIndex == 0)
        #expect(sut.currentState.queueState.playbackState == .playing)
    }

    @Test("transport actions delegate to the queue service")
    func transportActionsDelegate() {
        sut.dispatch(action: .togglePlayPause)
        sut.dispatch(action: .next)
        sut.dispatch(action: .previous)
        sut.dispatch(action: .skipTo(itemID: "item-0"))
        sut.dispatch(action: .cycleSpeed)
        sut.dispatch(action: .stop)

        #expect(mockPlaybackQueueService.togglePlayPauseCallCount == 1)
        #expect(mockPlaybackQueueService.nextCallCount == 1)
        #expect(mockPlaybackQueueService.previousCallCount == 1)
        #expect(mockPlaybackQueueService.skipCallCount == 1)
        #expect(mockPlaybackQueueService.lastSkippedToItemID == "item-0")
        #expect(mockPlaybackQueueService.cycleSpeedCallCount == 1)
        #expect(mockPlaybackQueueService.stopCallCount == 1)
    }

    @Test("queue sheet presents and dismisses")
    func queueSheetPresentation() {
        sut.dispatch(action: .showQueueSheet)
        #expect(sut.currentState.isQueueSheetPresented == true)

        sut.dispatch(action: .dismissQueueSheet)
        #expect(sut.currentState.isQueueSheetPresented == false)
    }

    @Test("queue going inactive dismisses the sheet")
    func sheetDismissedWhenQueueEnds() async throws {
        mockPlaybackQueueService.simulateState(makeActiveState())
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        sut.dispatch(action: .showQueueSheet)

        mockPlaybackQueueService.simulateState(.idle)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.isQueueSheetPresented == false)
        #expect(sut.currentState.queueState.currentIndex == nil)
    }
}
