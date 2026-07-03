import AVFoundation
import Combine
import EntropyCore
import Foundation

/// Live implementation of `PlaybackQueueService`.
@MainActor
final class LivePlaybackQueueService: PlaybackQueueService {
    private let ttsService: TextToSpeechService
    private let analyticsService: AnalyticsService?
    private let engagementEventsService: EngagementEventsService?
    /// Injectable so tests can post AVAudioSession notifications without leaking them.
    private let notificationCenter: NotificationCenter
    private let nowPlayingController = NowPlayingController()
    private let stateSubject = CurrentValueSubject<PlaybackQueueState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()

    /// Items that actually reached the synthesizer this session.
    private var playedItemIDs = Set<String>()

    /// True while the current pause was initiated by an audio interruption.
    private var pausedByInterruption = false

    /// Set when the speed preset changed while paused.
    private var needsRespeakOnResume = false

    /// Serializes Live Activity pushes via generation tracking.
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
        engagementEventsService: EngagementEventsService? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.ttsService = ttsService
        self.analyticsService = analyticsService
        self.engagementEventsService = engagementEventsService
        self.notificationCenter = notificationCenter
        nowPlayingController.attach(to: self)
        setupTTSBindings()
        setupAudioSessionEventHandling()
    }

    // MARK: - PlaybackQueueService

    func play(items: [PlaybackItem], mode: PlaybackMode) {
        guard !items.isEmpty else { return }

        // Replacing an active briefing must still emit its terminal analytics event.
        if currentState.mode == .briefing, currentState.currentIndex != nil {
            analyticsService?.logEvent(.briefingStopped(itemsPlayed: playedItemIDs.count))
        }
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
        if let item = currentState.currentItem {
            TTSLiveActivityController.shared.start(
                displayInfo: .init(title: item.title, source: item.sourceName,
                                   position: currentState.queuePositionLabel),
                speedLabel: currentState.speedPreset.label
            )
        }

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
            if needsRespeakOnResume { speakCurrentItem() } else { ttsService.resume() }
        case .idle:
            break
        }
    }

    func next() {
        guard currentState.hasNext, let index = currentState.currentIndex else { return }
        if currentState.mode == .briefing {
            analyticsService?.logEvent(.briefingItemSkipped)
            recordSkipEngagement()
        }
        advance(to: index + 1)
    }

    func previous() {
        guard currentState.hasPrevious, let index = currentState.currentIndex else { return }
        // Unlike `next()`, going backward isn't a disinterest signal — a
        // listener hits "previous" to replay something, not to skip past
        // it — so this only logs analytics, never `recordSkipEngagement()`.
        if currentState.mode == .briefing { analyticsService?.logEvent(.briefingItemSkipped) }
        advance(to: index - 1)
    }

    func skip(to itemID: String) {
        guard let target = currentState.items.firstIndex(where: { $0.id == itemID }),
              let currentIndex = currentState.currentIndex,
              target != currentIndex
        else { return }
        if currentState.mode == .briefing {
            analyticsService?.logEvent(.briefingItemSkipped)
            // Same rationale as `previous()`: only a forward jump reflects
            // disinterest in the item being left; jumping backward doesn't.
            if target > currentIndex { recordSkipEngagement() }
        }
        advance(to: target)
    }

    func cycleSpeed() {
        let nextPreset = currentState.speedPreset.next()
        updateState { state in
            state.speedPreset = nextPreset
            if state.currentIndex != nil { state.itemProgress = 0.0 }
        }

        guard currentState.currentIndex != nil else {
            analyticsService?.logEvent(.ttsSpeedChanged(speed: nextPreset.label))
            syncLiveActivity()
            return
        }

        switch currentState.playbackState {
        case .playing: speakCurrentItem()
        case .paused: needsRespeakOnResume = true
        case .idle: break
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

    /// Feeds a skipped-away-from article back into personalization as a
    /// negative signal. Only articles carry a signal — skipping past the
    /// digest narration isn't a statement about topic interest.
    private func recordSkipEngagement() {
        guard let engagementEventsService,
              case let .article(article) = currentState.currentItem?.kind
        else { return }
        let event = EngagementEvent(from: article, kind: .dismissed)
        let service = UncheckedSendableBox(value: engagementEventsService)
        Task {
            await service.value.record(event)
        }
    }

    private func speakCurrentItem() {
        guard let item = currentState.currentItem else { return }
        needsRespeakOnResume = false
        playedItemIDs.insert(item.id)
        ttsService.speak(text: item.speechText, language: item.language, rate: currentState.speedPreset.rate)
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
        syncLiveActivity()
    }

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

    // MARK: - TTS Bindings

    private func setupTTSBindings() {
        // `.idle` from TTS is not mapped to queue state — would flicker UI.
        // Queue owns idle transitions via teardownPlayback; auto-advance is driven by
        // the explicit finish event, never ambiguous with cancellation.
        ttsService.playbackStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ttsState in
                guard let self, self.currentState.currentIndex != nil else { return }
                guard ttsState == .playing || ttsState == .paused else { return }
                self.updateState { $0.playbackState = ttsState }
                // Progress events stop while paused; push play/pause to Activity immediately.
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
                // Finish event is delivered one runloop hop after sending. If a new
                // utterance started in that window (queue was replaced), the event
                // belongs to the previous queue — acting on it would skip ahead.
                guard self.ttsService.currentPlaybackState == .idle else { return }
                guard let index = self.currentState.currentIndex else { return }
                if self.currentState.hasNext {
                    self.advance(to: index + 1)
                } else {
                    if self.currentState.mode == .briefing { self.analyticsService?.logEvent(.briefingCompleted) }
                    self.teardownPlayback()
                }
            }
            .store(in: &cancellables)
        // `willSpeakRangeOfSpeechString` fires per character (~100Hz); throttle
        // Live Activity path only — each update spawns an actor-isolated call.
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

        // Headphones unplugged while playing → pause per system convention for spoken audio.
        notificationCenter.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, self.currentState.playbackState == .playing,
                      let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
                      reason == .oldDeviceUnavailable
                else { return }
                self.ttsService.pause()
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
            if currentState.playbackState == .playing { ttsService.pause(); pausedByInterruption = true }
        case .ended:
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            let wasInterruptionPause = pausedByInterruption
            pausedByInterruption = false
            if options.contains(.shouldResume), wasInterruptionPause,
               currentState.playbackState == .paused
            {
                if needsRespeakOnResume { speakCurrentItem() } else { ttsService.resume() }
            }
        @unknown default: break
        }
    }

    // MARK: - Live Activity

    /// Pushes playback state to Live Activity (safe no-op when none running).
    private func syncLiveActivity() {
        guard let item = currentState.currentItem else { return }
        let state = currentState
        liveActivitySyncGeneration += 1
        let generation = liveActivitySyncGeneration, previousTask = liveActivitySyncTask
        liveActivitySyncTask = Task { @MainActor [weak self] in
            await previousTask?.value
            guard let self, generation == self.liveActivitySyncGeneration else { return }
            await TTSLiveActivityController.shared.update(
                isPlaying: state.playbackState == .playing, progress: state.itemProgress,
                speedLabel: state.speedPreset.label,
                displayInfo: .init(title: item.title, source: item.sourceName,
                                   position: state.queuePositionLabel)
            )
        }
    }

    // MARK: - State

    private func updateState(_ transform: (inout PlaybackQueueState) -> Void) {
        var state = stateSubject.value, beforeNowPlaying = state
        transform(&state)
        stateSubject.send(state)
        // Skip the MPNowPlayingInfoCenter XPC write unless rendered fields changed.
        beforeNowPlaying.itemProgress = state.itemProgress
        if beforeNowPlaying != state { nowPlayingController.update(with: state) }
    }
}
