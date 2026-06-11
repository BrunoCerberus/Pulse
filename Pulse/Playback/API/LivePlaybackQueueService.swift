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
/// TTS Live Activity, and pauses/resumes around audio interruptions and
/// output-route changes.
///
/// Queue items are immutable snapshots (see `PlaybackItem`), so digest
/// regeneration or a runtime language switch never affects a playing queue.
/// Playback deliberately survives navigation; `stop()` is the only teardown.
@MainActor
final class LivePlaybackQueueService: PlaybackQueueService {
    private let ttsService: TextToSpeechService
    private let analyticsService: AnalyticsService?
    /// Injectable so tests can post AVAudioSession notifications without
    /// leaking them into other parallel-running service instances.
    private let notificationCenter: NotificationCenter
    private let nowPlayingController = NowPlayingController()
    private let stateSubject = CurrentValueSubject<PlaybackQueueState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()

    /// Items that actually reached the synthesizer this session, for accurate
    /// `briefingStopped(itemsPlayed:)` analytics (queue position would inflate
    /// the count when the user skips ahead).
    private var playedItemIDs = Set<String>()

    /// `true` while the current pause was initiated by an audio interruption
    /// (phone call, alarm) rather than the user. Only interruption-initiated
    /// pauses are auto-resumed when the system says `.shouldResume` — resuming
    /// a user's explicit pause because a call happened to end would speak out
    /// loud against their intent.
    private var pausedByInterruption = false

    /// Set when the speed preset changed while paused: the paused utterance
    /// still carries the old rate (rate is fixed per utterance), so the next
    /// resume re-speaks the item instead of continuing the stale utterance.
    private var needsRespeakOnResume = false

    /// Serializes Live Activity pushes: each sync awaits the previous one and
    /// is skipped when a newer sync has been requested since, so a slow
    /// ActivityKit update can never overwrite a fresher state.
    private var liveActivitySyncGeneration = 0
    private var liveActivitySyncTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<PlaybackQueueState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: PlaybackQueueState {
        stateSubject.value
    }

    init(
        ttsService: TextToSpeechService,
        analyticsService: AnalyticsService?,
        notificationCenter: NotificationCenter = .default
    ) {
        self.ttsService = ttsService
        self.analyticsService = analyticsService
        self.notificationCenter = notificationCenter
        nowPlayingController.attach(to: self)
        setupTTSBindings()
        setupAudioSessionEventHandling()
    }

    // MARK: - PlaybackQueueService

    func play(items: [PlaybackItem], mode: PlaybackMode) {
        guard !items.isEmpty else { return }

        // Replacing an active briefing must still emit its terminal analytics
        // event, or funnels see briefings that start and never end.
        logBriefingStoppedIfActive()
        playedItemIDs.removeAll()
        pausedByInterruption = false
        needsRespeakOnResume = false

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
        // An explicit user action supersedes any pending interruption resume.
        pausedByInterruption = false
        switch currentState.playbackState {
        case .playing:
            ttsService.pause()
        case .paused:
            resumePlayback()
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
        logItemSkippedIfBriefing()
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

        if currentState.currentIndex != nil {
            switch currentState.playbackState {
            case .playing:
                // Restart the current item at the new rate. The implicit
                // cancellation inside `speak()` fires `didCancel` (no finish
                // event), so this never triggers a spurious auto-advance.
                speakCurrentItem()
            case .paused:
                // Respect the pause: the rate is fixed per utterance, so mark
                // the paused utterance stale and re-speak on the next resume
                // instead of audibly restarting now.
                needsRespeakOnResume = true
            case .idle:
                break
            }
        }

        analyticsService?.logEvent(.ttsSpeedChanged(speed: nextPreset.label))
        syncLiveActivity()
    }

    func stop() {
        guard currentState.currentIndex != nil else { return }

        switch currentState.mode {
        case .briefing:
            analyticsService?.logEvent(.briefingStopped(itemsPlayed: playedItemIDs.count))
        case .singleArticle:
            analyticsService?.logEvent(.ttsStopped)
        }

        teardownPlayback()
    }

    // MARK: - Playback Internals

    private func speakCurrentItem() {
        guard let item = currentState.currentItem else { return }
        needsRespeakOnResume = false
        playedItemIDs.insert(item.id)
        ttsService.speak(text: item.speechText, language: item.language, rate: currentState.speedPreset.rate)
    }

    /// Resumes from pause, re-speaking the current item when a speed change
    /// while paused left the paused utterance at a stale rate.
    private func resumePlayback() {
        if needsRespeakOnResume {
            speakCurrentItem()
        } else {
            ttsService.resume()
        }
    }

    private func advance(to index: Int) {
        guard currentState.items.indices.contains(index) else { return }
        pausedByInterruption = false
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
        playedItemIDs.removeAll()
        pausedByInterruption = false
        needsRespeakOnResume = false
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

    /// Terminal analytics for a briefing being replaced by a new `play()`.
    private func logBriefingStoppedIfActive() {
        guard currentState.mode == .briefing, currentState.currentIndex != nil else { return }
        analyticsService?.logEvent(.briefingStopped(itemsPlayed: playedItemIDs.count))
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
                guard let self else { return }
                // The finish event is delivered one runloop hop after it was
                // sent. If a new utterance started in that window (the queue
                // was replaced), the event belongs to the previous queue —
                // acting on it would advance past the new queue's first item.
                guard self.ttsService.currentPlaybackState == .idle else { return }
                self.handleItemFinished()
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

    // MARK: - Audio Session Events

    /// Pauses on interruption (phone call, timer, another app's audio), resumes
    /// when the system says an interruption-initiated pause ended with
    /// `.shouldResume`, and pauses when the active output route disappears
    /// (headphones unplugged) per the system convention for spoken audio.
    private func setupAudioSessionEventHandling() {
        notificationCenter.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
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
                pausedByInterruption = true
            }
        case .ended:
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let wasInterruptionPause = pausedByInterruption
            pausedByInterruption = false
            // Resume only a pause this interruption caused. A user-initiated
            // pause stays paused no matter what the system suggests.
            if options.contains(.shouldResume), wasInterruptionPause,
               currentState.playbackState == .paused
            {
                resumePlayback()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard currentState.playbackState == .playing,
              let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable
        else { return }
        ttsService.pause()
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
    /// when none is running). Pushes are serialized and latest-wins: a stale
    /// in-flight update can never land after a newer one.
    private func syncLiveActivity() {
        let state = currentState
        guard let item = state.currentItem else { return }
        liveActivitySyncGeneration += 1
        let generation = liveActivitySyncGeneration
        let previous = liveActivitySyncTask
        liveActivitySyncTask = Task { @MainActor [weak self] in
            await previous?.value
            guard let self, generation == self.liveActivitySyncGeneration else { return }
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
        var nowPlayingBefore = state
        transform(&state)
        stateSubject.send(state)
        // Progress ticks arrive per spoken character (~100Hz) and Now Playing
        // renders no progress field — skip the MPNowPlayingInfoCenter XPC
        // write unless something it actually renders changed.
        nowPlayingBefore.itemProgress = state.itemProgress
        if nowPlayingBefore != state {
            nowPlayingController.update(with: state)
        }
    }
}
