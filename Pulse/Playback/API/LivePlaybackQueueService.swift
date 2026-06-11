import AVFoundation
import Combine
import EntropyCore
import Foundation

/// Live implementation of `PlaybackQueueService`.
///
/// Single owner of `TextToSpeechService`: every speech session in the app —
/// the single-article "Listen" and the Premium audio briefing — flows through
/// here. The service auto-advances on natural utterance finish, owns the Now
/// Playing entry + remote commands (via `NowPlayingController`), drives the
/// TTS Live Activity, and pauses/resumes around audio interruptions.
///
/// Queue items are immutable snapshots (see `PlaybackItem`), so digest
/// regeneration or a runtime language switch never affects a playing queue.
/// Playback deliberately survives navigation; `stop()` is the only teardown.
@MainActor
final class LivePlaybackQueueService: PlaybackQueueService {
    private let ttsService: TextToSpeechService
    private let analyticsService: AnalyticsService?
    private let nowPlayingController = NowPlayingController()
    private let stateSubject = CurrentValueSubject<PlaybackQueueState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<PlaybackQueueState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: PlaybackQueueState {
        stateSubject.value
    }

    init(ttsService: TextToSpeechService, analyticsService: AnalyticsService?) {
        self.ttsService = ttsService
        self.analyticsService = analyticsService
        nowPlayingController.attach(to: self)
        setupTTSBindings()
        setupInterruptionHandling()
    }

    // MARK: - PlaybackQueueService

    func play(items: [PlaybackItem], mode: PlaybackMode) {
        guard !items.isEmpty else { return }

        updateState { state in
            state.items = items
            state.currentIndex = 0
            state.mode = mode
            state.itemProgress = 0.0
            state.playbackState = .playing
        }
        speakCurrentItem()
        startLiveActivity()

        switch mode {
        case .briefing:
            analyticsService?.logEvent(.briefingStarted(itemCount: items.count))
        case .singleArticle:
            analyticsService?.logEvent(.ttsStarted)
        }
    }

    func togglePlayPause() {
        guard currentState.currentIndex != nil else { return }
        switch currentState.playbackState {
        case .playing:
            ttsService.pause()
        case .paused:
            ttsService.resume()
        case .idle:
            break
        }
    }

    func next() {
        guard currentState.hasNext, let index = currentState.currentIndex else { return }
        logItemSkippedIfBriefing()
        advance(to: index + 1)
    }

    func previous() {
        guard currentState.hasPrevious, let index = currentState.currentIndex else { return }
        advance(to: index - 1)
    }

    func skip(to itemID: String) {
        guard let target = currentState.items.firstIndex(where: { $0.id == itemID }),
              target != currentState.currentIndex
        else { return }
        logItemSkippedIfBriefing()
        advance(to: target)
    }

    func cycleSpeed() {
        let nextPreset = currentState.speedPreset.next()
        updateState { state in
            state.speedPreset = nextPreset
            if state.currentIndex != nil {
                state.itemProgress = 0.0
            }
        }

        // Restart the current item at the new rate. The implicit cancellation
        // inside `speak()` fires `didCancel` (no finish event), so this never
        // triggers a spurious auto-advance.
        if currentState.currentIndex != nil,
           currentState.playbackState == .playing || currentState.playbackState == .paused
        {
            speakCurrentItem()
        }

        analyticsService?.logEvent(.ttsSpeedChanged(speed: nextPreset.label))
        syncLiveActivity()
    }

    func stop() {
        guard currentState.currentIndex != nil else { return }

        switch currentState.mode {
        case .briefing:
            let itemsPlayed = (currentState.currentIndex ?? 0) + 1
            analyticsService?.logEvent(.briefingStopped(itemsPlayed: itemsPlayed))
        case .singleArticle:
            analyticsService?.logEvent(.ttsStopped)
        }

        teardownPlayback()
    }

    // MARK: - Playback Internals

    private func speakCurrentItem() {
        guard let item = currentState.currentItem else { return }
        ttsService.speak(text: item.speechText, language: item.language, rate: currentState.speedPreset.rate)
    }

    private func advance(to index: Int) {
        guard currentState.items.indices.contains(index) else { return }
        updateState { state in
            state.currentIndex = index
            state.itemProgress = 0.0
            state.playbackState = .playing
        }
        speakCurrentItem()
        // The activity spans the whole session; item changes are pushed as
        // ContentState updates so the Lock Screen never flickers.
        syncLiveActivity()
    }

    /// Natural end of an utterance: advance, or finish the whole queue.
    private func handleItemFinished() {
        guard let index = currentState.currentIndex else { return }

        if currentState.hasNext {
            advance(to: index + 1)
        } else {
            if currentState.mode == .briefing {
                analyticsService?.logEvent(.briefingCompleted)
            }
            teardownPlayback()
        }
    }

    /// Stops speech, deactivates the audio session, clears the queue, and
    /// tears down Now Playing + the Live Activity. Speed preset is preserved.
    private func teardownPlayback() {
        ttsService.stop()
        updateState { state in
            let speed = state.speedPreset
            state = .idle
            state.speedPreset = speed
        }
        TTSLiveActivityController.shared.end()
    }

    private func logItemSkippedIfBriefing() {
        guard currentState.mode == .briefing else { return }
        analyticsService?.logEvent(.briefingItemSkipped)
    }

    // MARK: - TTS Bindings

    private func setupTTSBindings() {
        // `.idle` from the TTS service is deliberately NOT mapped into queue
        // state: it fires transiently between items (didFinish/didCancel) and
        // would flicker the player UI. The queue owns its idle transitions
        // (`teardownPlayback`); auto-advance is driven by the explicit finish
        // event below, which is never ambiguous with cancellation.
        ttsService.playbackStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ttsState in
                guard let self, self.currentState.currentIndex != nil else { return }
                guard ttsState == .playing || ttsState == .paused else { return }
                self.updateState { $0.playbackState = ttsState }
                // Progress events stop while paused, so push play/pause
                // transitions to the Live Activity immediately.
                self.syncLiveActivity()
            }
            .store(in: &cancellables)

        ttsService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self, self.currentState.currentIndex != nil else { return }
                self.updateState { $0.itemProgress = progress }
            }
            .store(in: &cancellables)

        ttsService.didFinishUtterancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleItemFinished()
            }
            .store(in: &cancellables)

        // `willSpeakRangeOfSpeechString` fires per character (~100Hz). Each Live
        // Activity update spawns an actor-isolated call into ActivityKit, which
        // is wasteful at that rate — throttle the Live Activity path only.
        ttsService.progressPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.syncLiveActivity()
            }
            .store(in: &cancellables)
    }

    // MARK: - Audio Interruptions

    /// Pauses on interruption (phone call, timer, another app's audio) and
    /// resumes when the system says the interruption ended with `.shouldResume`.
    private func setupInterruptionHandling() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &cancellables)
    }

    private func handleInterruption(_ notification: Notification) {
        guard currentState.currentIndex != nil,
              let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            if currentState.playbackState == .playing {
                ttsService.pause()
            }
        case .ended:
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume), currentState.playbackState == .paused {
                ttsService.resume()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard let item = currentState.currentItem else { return }
        TTSLiveActivityController.shared.start(
            currentTitle: item.title,
            currentSource: item.sourceName,
            speedLabel: currentState.speedPreset.label,
            queuePosition: currentState.queuePositionLabel
        )
    }

    /// Pushes current playback state to the active Live Activity (safe no-op
    /// when none is running).
    private func syncLiveActivity() {
        let state = currentState
        guard let item = state.currentItem else { return }
        Task { @MainActor in
            await TTSLiveActivityController.shared.update(
                isPlaying: state.playbackState == .playing,
                progress: state.itemProgress,
                speedLabel: state.speedPreset.label,
                currentTitle: item.title,
                currentSource: item.sourceName,
                queuePosition: state.queuePositionLabel
            )
        }
    }

    // MARK: - State

    private func updateState(_ transform: (inout PlaybackQueueState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
        nowPlayingController.update(with: state)
    }
}
