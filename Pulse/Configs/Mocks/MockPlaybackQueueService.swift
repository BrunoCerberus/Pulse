import Combine
import Foundation

final class MockPlaybackQueueService: PlaybackQueueService {
    private let stateSubject = CurrentValueSubject<PlaybackQueueState, Never>(.idle)

    // MARK: - Call Tracking

    private(set) var playCallCount = 0
    private(set) var lastPlayedItems: [PlaybackItem]?
    private(set) var lastPlayedMode: PlaybackMode?
    private(set) var togglePlayPauseCallCount = 0
    private(set) var nextCallCount = 0
    private(set) var previousCallCount = 0
    private(set) var skipCallCount = 0
    private(set) var lastSkippedToItemID: String?
    private(set) var cycleSpeedCallCount = 0
    private(set) var stopCallCount = 0

    // MARK: - Protocol

    var statePublisher: AnyPublisher<PlaybackQueueState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: PlaybackQueueState {
        stateSubject.value
    }

    func play(items: [PlaybackItem], mode: PlaybackMode) {
        playCallCount += 1
        lastPlayedItems = items
        lastPlayedMode = mode

        guard !items.isEmpty else { return }
        var state = PlaybackQueueState.idle
        state.items = items
        state.currentIndex = 0
        state.mode = mode
        state.playbackState = .playing
        stateSubject.send(state)
    }

    func togglePlayPause() {
        togglePlayPauseCallCount += 1
        var state = stateSubject.value
        switch state.playbackState {
        case .playing: state.playbackState = .paused
        case .paused: state.playbackState = .playing
        case .idle: return
        }
        stateSubject.send(state)
    }

    func next() {
        nextCallCount += 1
        var state = stateSubject.value
        guard state.hasNext, let index = state.currentIndex else { return }
        state.currentIndex = index + 1
        state.itemProgress = 0.0
        stateSubject.send(state)
    }

    func previous() {
        previousCallCount += 1
        var state = stateSubject.value
        guard state.hasPrevious, let index = state.currentIndex else { return }
        state.currentIndex = index - 1
        state.itemProgress = 0.0
        stateSubject.send(state)
    }

    func skip(to itemID: String) {
        skipCallCount += 1
        lastSkippedToItemID = itemID
        var state = stateSubject.value
        guard let target = state.items.firstIndex(where: { $0.id == itemID }) else { return }
        state.currentIndex = target
        state.itemProgress = 0.0
        stateSubject.send(state)
    }

    func cycleSpeed() {
        cycleSpeedCallCount += 1
        var state = stateSubject.value
        state.speedPreset = state.speedPreset.next()
        stateSubject.send(state)
    }

    func stop() {
        stopCallCount += 1
        stateSubject.send(.idle)
    }

    // MARK: - Test Helpers

    func simulateState(_ state: PlaybackQueueState) {
        stateSubject.send(state)
    }

    func reset() {
        playCallCount = 0
        lastPlayedItems = nil
        lastPlayedMode = nil
        togglePlayPauseCallCount = 0
        nextCallCount = 0
        previousCallCount = 0
        skipCallCount = 0
        lastSkippedToItemID = nil
        cycleSpeedCallCount = 0
        stopCallCount = 0
        stateSubject.send(.idle)
    }
}
