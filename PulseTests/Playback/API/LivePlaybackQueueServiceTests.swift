import AVFoundation
import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LivePlaybackQueueService Tests")
@MainActor
struct LivePlaybackQueueServiceTests {
    let mockTTSService: MockTextToSpeechService
    let mockAnalyticsService: MockAnalyticsService
    let mockEngagementEventsService: MockEngagementEventsService
    /// Per-test center so posted AVAudioSession notifications never leak into
    /// other parallel-running service instances.
    let notificationCenter: NotificationCenter
    let sut: LivePlaybackQueueService

    init() {
        mockTTSService = MockTextToSpeechService()
        mockAnalyticsService = MockAnalyticsService()
        mockEngagementEventsService = MockEngagementEventsService()
        notificationCenter = NotificationCenter()
        sut = LivePlaybackQueueService(
            ttsService: mockTTSService,
            analyticsService: mockAnalyticsService,
            engagementEventsService: mockEngagementEventsService,
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

    // MARK: - Play

    @Test("play starts the first item and publishes an active state")
    func playStartsFirstItem() {
        let items = makeItems(3)

        sut.play(items: items, mode: .briefing)

        #expect(mockTTSService.speakCallCount == 1)
        #expect(mockTTSService.lastSpokenText == "Speech text 0")
        #expect(mockTTSService.lastLanguage == "en")
        #expect(sut.currentState.currentIndex == 0)
        #expect(sut.currentState.items.count == 3)
        #expect(sut.currentState.mode == .briefing)
        #expect(sut.currentState.playbackState == .playing)
    }

    @Test("play with empty items is a no-op")
    func playEmptyItemsNoOp() {
        sut.play(items: [], mode: .briefing)

        #expect(mockTTSService.speakCallCount == 0)
        #expect(sut.currentState.currentIndex == nil)
    }

    @Test("play replaces the current queue")
    func playReplacesQueue() {
        sut.play(items: makeItems(3), mode: .briefing)
        let replacement = [
            PlaybackItem(
                id: "replacement",
                kind: .article(Article.mockArticles[0]),
                title: "Replacement",
                sourceName: "Source",
                speechText: "Replacement text",
                language: "en"
            ),
        ]

        sut.play(items: replacement, mode: .singleArticle)

        #expect(sut.currentState.items.count == 1)
        #expect(sut.currentState.currentIndex == 0)
        #expect(sut.currentState.mode == .singleArticle)
        #expect(mockTTSService.lastSpokenText == "Replacement text")
    }

    @Test("play logs briefingStarted for briefing mode and ttsStarted for single article")
    func playLogsAnalytics() {
        sut.play(items: makeItems(3), mode: .briefing)
        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case let .briefingStarted(itemCount) = event { return itemCount == 3 }
            return false
        })

        sut.play(items: makeItems(1), mode: .singleArticle)
        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case .ttsStarted = event { return true }
            return false
        })
    }

    // MARK: - Auto-Advance

    @Test("natural finish advances to the next item")
    func finishAdvancesToNextItem() async throws {
        sut.play(items: makeItems(2), mode: .briefing)

        mockTTSService.simulateFinished()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.currentIndex == 1)
        #expect(mockTTSService.speakCallCount == 2)
        #expect(mockTTSService.lastSpokenText == "Speech text 1")
        #expect(sut.currentState.playbackState == .playing)
    }

    @Test("natural finish of the last item tears down the queue")
    func finishLastItemEndsQueue() async throws {
        sut.play(items: makeItems(1), mode: .briefing)

        mockTTSService.simulateFinished()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.currentIndex == nil)
        #expect(sut.currentState.items.isEmpty)
        #expect(mockTTSService.stopCallCount >= 1)
        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case .briefingCompleted = event { return true }
            return false
        })
    }

    @Test("completing a single-article session does not log briefingCompleted")
    func singleArticleCompletionLogsNoBriefingEvent() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        mockTTSService.simulateFinished()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.currentIndex == nil)
        #expect(!mockAnalyticsService.loggedEvents.contains { event in
            if case .briefingCompleted = event { return true }
            return false
        })
    }

    // MARK: - Manual Navigation

    @Test("next advances and previous goes back")
    func nextAndPrevious() {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.next()
        #expect(sut.currentState.currentIndex == 1)
        #expect(mockTTSService.lastSpokenText == "Speech text 1")

        sut.previous()
        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.lastSpokenText == "Speech text 0")
    }

    @Test("next at the end of the queue is a no-op")
    func nextAtEndNoOp() {
        sut.play(items: makeItems(1), mode: .briefing)

        sut.next()

        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.speakCallCount == 1)
    }

    @Test("previous on the first item is a no-op")
    func previousAtStartNoOp() {
        sut.play(items: makeItems(2), mode: .briefing)

        sut.previous()

        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.speakCallCount == 1)
    }

    @Test("skip jumps to the item with the given ID")
    func skipJumpsToItem() {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.skip(to: "item-2")

        #expect(sut.currentState.currentIndex == 2)
        #expect(mockTTSService.lastSpokenText == "Speech text 2")
    }

    @Test("skip to the current item or an unknown ID is a no-op")
    func skipNoOps() {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.skip(to: "item-0")
        sut.skip(to: "unknown")

        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.speakCallCount == 1)
    }

    @Test("manual skips log briefingItemSkipped in briefing mode only")
    func skipAnalytics() {
        sut.play(items: makeItems(3), mode: .briefing)
        sut.next()

        let skippedCount = mockAnalyticsService.loggedEvents.filter { event in
            if case .briefingItemSkipped = event { return true }
            return false
        }.count
        #expect(skippedCount == 1)
    }

    // MARK: - Skip Engagement Signal

    @Test("next in briefing mode records a dismissed engagement for the skipped article")
    func nextRecordsDismissedEngagement() async throws {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.next()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockEngagementEventsService.recordedEvents.count == 1)
        #expect(mockEngagementEventsService.recordedEvents.first?.kind == .dismissed)
        #expect(mockEngagementEventsService.recordedEvents.first?.articleID == Article.mockArticles[0].id)
    }

    @Test("previous in briefing mode records a dismissed engagement for the skipped article")
    func previousRecordsDismissedEngagement() async throws {
        sut.play(items: makeItems(3), mode: .briefing)
        sut.next()

        sut.previous()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockEngagementEventsService.recordedEvents.count == 2)
        #expect(mockEngagementEventsService.recordedEvents.last?.kind == .dismissed)
    }

    @Test("skip(to:) in briefing mode records a dismissed engagement for the skipped article")
    func skipToRecordsDismissedEngagement() async throws {
        sut.play(items: makeItems(3), mode: .briefing)

        sut.skip(to: "item-2")
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockEngagementEventsService.recordedEvents.count == 1)
        #expect(mockEngagementEventsService.recordedEvents.first?.articleID == Article.mockArticles[0].id)
    }

    @Test("skipping past the digest item records no engagement signal")
    func skipPastDigestRecordsNoEngagement() async throws {
        let digest = DailyDigest(id: "digest-1", summary: "Today's summary", sourceArticles: [], generatedAt: Date())
        let digestItem = PlaybackItem.digest(digest, language: "en")
        sut.play(items: [digestItem] + makeItems(2), mode: .briefing)

        sut.next()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockEngagementEventsService.recordedEvents.isEmpty)
    }

    @Test("next in single-article mode records no engagement signal")
    func nextSingleArticleRecordsNoEngagement() async throws {
        sut.play(items: makeItems(2), mode: .singleArticle)

        sut.next()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockEngagementEventsService.recordedEvents.isEmpty)
    }

    // MARK: - Toggle / Stop

    @Test("togglePlayPause pauses when playing and resumes when paused")
    func togglePlayPause() async throws {
        sut.play(items: makeItems(1), mode: .singleArticle)

        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(mockTTSService.pauseCallCount == 1)
        #expect(sut.currentState.playbackState == .paused)

        sut.togglePlayPause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(mockTTSService.resumeCallCount == 1)
        #expect(sut.currentState.playbackState == .playing)
    }

    @Test("togglePlayPause with no active queue is a no-op")
    func toggleInactiveNoOp() {
        sut.togglePlayPause()

        #expect(mockTTSService.pauseCallCount == 0)
        #expect(mockTTSService.resumeCallCount == 0)
    }

    @Test("stop clears the queue and stops speech")
    func stopClearsQueue() {
        sut.play(items: makeItems(2), mode: .briefing)

        sut.stop()

        #expect(sut.currentState.currentIndex == nil)
        #expect(sut.currentState.items.isEmpty)
        #expect(mockTTSService.stopCallCount == 1)
        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case let .briefingStopped(itemsPlayed) = event { return itemsPlayed == 1 }
            return false
        })
    }

    @Test("stopping a single-article session logs ttsStopped")
    func stopSingleArticleLogsTTSStopped() {
        sut.play(items: makeItems(1), mode: .singleArticle)

        sut.stop()

        #expect(mockAnalyticsService.loggedEvents.contains { event in
            if case .ttsStopped = event { return true }
            return false
        })
    }

    @Test("stop with no active queue is a no-op")
    func stopInactiveNoOp() {
        sut.stop()

        #expect(mockTTSService.stopCallCount == 0)
        #expect(mockAnalyticsService.loggedEvents.isEmpty)
    }

    // MARK: - Speed

    @Test("cycleSpeed when inactive only changes the preset")
    func cycleSpeedInactive() {
        sut.cycleSpeed()

        #expect(sut.currentState.speedPreset == .fast)
        #expect(mockTTSService.speakCallCount == 0)
    }

    @Test("speed preset survives queue teardown")
    func speedPresetSurvivesTeardown() {
        sut.cycleSpeed()
        sut.play(items: makeItems(1), mode: .singleArticle)

        sut.stop()

        #expect(sut.currentState.speedPreset == .fast)
        #expect(mockTTSService.lastRate == TTSSpeedPreset.fast.rate)
    }
}
