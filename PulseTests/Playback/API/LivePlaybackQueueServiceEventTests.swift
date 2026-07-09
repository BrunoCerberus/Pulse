import AVFoundation
import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Event-handling coverage for `LivePlaybackQueueService`: speed changes
/// while paused, audio interruptions, route changes, stale TTS events across
/// queue replacement, and briefing analytics accuracy. Split from
/// `LivePlaybackQueueServiceTests` to keep each suite within lint budgets.
@Suite("LivePlaybackQueueService Event Tests")
@MainActor
struct LivePlaybackQueueServiceEventTests {
    let mockTTSService: MockTextToSpeechService
    let mockAnalyticsService: MockAnalyticsService
    /// Per-test center so posted AVAudioSession notifications never leak into
    /// other parallel-running service instances.
    let notificationCenter: NotificationCenter
    let sut: LivePlaybackQueueService

    init() {
        mockTTSService = MockTextToSpeechService()
        mockAnalyticsService = MockAnalyticsService()
        notificationCenter = NotificationCenter()
        sut = LivePlaybackQueueService(
            ttsService: mockTTSService,
            analyticsService: mockAnalyticsService,
            notificationCenter: notificationCenter
        )
    }

    private func makeItems(_ count: Int) -> [PlaybackItem] {
        (0 ..< count).map { index in
            PlaybackItem(
                id: "item-\(index)",
                kind: .article(Article.mockArticles[index % Article.mockArticles.count]),
                title: "Title \(index)",
                sourceName: "Source \(index)",
                speechText: "Speech text \(index)",
                language: "en"
            )
        }
    }

    // MARK: - Speed While Paused

    @Test("cycleSpeed while paused stays paused and applies the new rate on resume")
    func cycleSpeedWhilePausedStaysPaused() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)
        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.playbackState == .paused)

        sut.cycleSpeed()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Still paused: no re-speak fired against the user's pause.
        #expect(sut.currentState.playbackState == .paused)
        #expect(sut.currentState.speedPreset == .fast)
        #expect(mockTTSService.speakCallCount == 1)

        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Resume re-speaks at the new rate instead of continuing the stale
        // utterance (rate is fixed per utterance).
        #expect(sut.currentState.playbackState == .playing)
        #expect(mockTTSService.speakCallCount == 2)
        #expect(mockTTSService.resumeCallCount == 0)
        #expect(mockTTSService.lastRate == TTSSpeedPreset.fast.rate)
    }

    // MARK: - Audio Interruptions

    private func postInterruption(_ type: AVAudioSession.InterruptionType, shouldResume: Bool = false) {
        var userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: type.rawValue,
        ]
        if shouldResume {
            userInfo[AVAudioSessionInterruptionOptionKey] =
                AVAudioSession.InterruptionOptions.shouldResume.rawValue
        }
        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: userInfo
        )
    }

    @Test("interruption pauses playback and shouldResume resumes it")
    func interruptionPausesAndResumes() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        postInterruption(.began)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(mockTTSService.pauseCallCount == 1)
        #expect(sut.currentState.playbackState == .paused)

        postInterruption(.ended, shouldResume: true)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(mockTTSService.resumeCallCount == 1)
        #expect(sut.currentState.playbackState == .playing)
    }

    @Test("interruption end never resumes a pause the user initiated")
    func interruptionEndRespectsUserPause() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)
        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.playbackState == .paused)

        // A call comes in and ends while the user has playback paused: the
        // .began branch is a no-op (already paused), and .ended must not
        // start narrating against the user's explicit pause.
        postInterruption(.began)
        postInterruption(.ended, shouldResume: true)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.resumeCallCount == 0)
        #expect(sut.currentState.playbackState == .paused)
    }

    @Test("user resume during an interruption clears the pending auto-resume")
    func userResumeDuringInterruptionClearsFlag() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        postInterruption(.began)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.playbackState == .paused)

        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.playbackState == .playing)
        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        postInterruption(.ended, shouldResume: true)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // The second (user) pause must survive the system's resume hint.
        #expect(sut.currentState.playbackState == .paused)
        #expect(mockTTSService.resumeCallCount == 1)
    }

    // MARK: - Route Changes

    @Test("output route disappearing pauses playback")
    func routeChangePausesPlayback() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        notificationCenter.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey:
                    AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue,
            ]
        )
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.pauseCallCount == 1)
        #expect(sut.currentState.playbackState == .paused)
    }

    @Test("other route changes do not pause playback")
    func newDeviceRouteChangeIgnored() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        notificationCenter.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey:
                    AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue,
            ]
        )
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.pauseCallCount == 0)
        #expect(sut.currentState.playbackState == .playing)
    }

    // MARK: - Stale Events Across Queue Replacement

    @Test("a finish event from the replaced queue does not advance the new queue")
    func staleFinishAfterReplaceDoesNotAdvance() async throws {
        sut.play(items: makeItems(2), mode: .briefing)

        // The finish event hops the main queue before delivery; replacing the
        // queue in that window must not let the stale event advance past the
        // new queue's first item.
        mockTTSService.simulateFinished()
        sut.play(items: makeItems(2), mode: .briefing)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.lastSpokenText == "Speech text 0")
    }

    // MARK: - Briefing Analytics Accuracy

    @Test("replacing an active briefing logs its terminal briefingStopped event")
    func replacingBriefingLogsTerminalEvent() {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.play(items: makeItems(2), mode: .briefing)

        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case let .briefingStopped(itemsPlayed) = event {
                return itemsPlayed == 1
            }
            return false
        })
    }

    @Test("briefingStopped counts unique items played, not queue position")
    func briefingStoppedCountsUniqueItemsPlayed() {
        sut.play(items: makeItems(3), mode: .briefing)
        sut.next()
        sut.previous()

        sut.stop()

        // item-0 and item-1 actually reached the synthesizer; revisiting
        // item-0 must not double-count, and position (1) must not undercount.
        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case let .briefingStopped(itemsPlayed) = event {
                return itemsPlayed == 2
            }
            return false
        })
    }

    @Test("previous logs briefingItemSkipped like next and skip")
    func previousLogsItemSkipped() {
        sut.play(items: makeItems(3), mode: .briefing)
        sut.next()
        sut.previous()

        let skippedCount = mockAnalyticsService.loggedEvents.filter { event in
            if case .briefingItemSkipped = event {
                return true
            }
            return false
        }.count
        #expect(skippedCount == 2)
    }
}
