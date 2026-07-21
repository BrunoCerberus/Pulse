import AVFoundation
import Combine
import EntropyCore
@testable import Pulse
import Testing

@Suite("LivePlaybackQueueService Extended Tests")
@MainActor
struct LivePlaybackQueueServiceExtendedTests {
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
            notificationCenter: notificationCenter,
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
                language: "en",
            )
        }
    }

    // MARK: - Speed

    @Test("cycleSpeed while playing re-speaks the current item at the new rate")
    func cycleSpeedRestartsCurrentItem() {
        sut.play(items: makeItems(2), mode: .briefing)

        sut.cycleSpeed()

        #expect(sut.currentState.speedPreset == .fast)
        #expect(sut.currentState.currentIndex == 0)
        #expect(mockTTSService.speakCallCount == 2)
        #expect(mockTTSService.lastSpokenText == "Speech text 0")
        #expect(mockTTSService.lastRate == TTSSpeedPreset.fast.rate)
    }

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

    // MARK: - Transient TTS States

    @Test("stale cancel callback does not tear down the queue")
    func staleCancelIgnored() async throws {
        sut.play(items: makeItems(2), mode: .briefing)

        mockTTSService.simulateStaleCancelCallback()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.currentIndex == 0)
        #expect(sut.currentState.playbackState == .playing)
    }

    // MARK: - State Computed Properties

    @Test("queue state computed properties reflect position")
    func stateComputedProperties() {
        sut.play(items: makeItems(3), mode: .briefing)

        #expect(sut.currentState.hasNext == true)
        #expect(sut.currentState.hasPrevious == false)
        #expect(sut.currentState.queuePositionLabel == "1/3")
        #expect(sut.currentState.currentItem?.id == "item-0")

        sut.next()
        sut.next()

        #expect(sut.currentState.hasNext == false)
        #expect(sut.currentState.hasPrevious == true)
        #expect(sut.currentState.queuePositionLabel == "3/3")
    }

    @Test("single-article mode has no queue position label")
    func singleArticleNoPositionLabel() {
        sut.play(items: makeItems(1), mode: .singleArticle)

        #expect(sut.currentState.queuePositionLabel == nil)
    }

    @Test("overallProgress weights items equally")
    func overallProgress() async throws {
        sut.play(items: makeItems(2), mode: .briefing)

        mockTTSService.simulateProgress(0.5)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(abs(sut.currentState.overallProgress - 0.25) < 0.001)

        mockTTSService.simulateFinished()
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.currentIndex == 1)
        #expect(abs(sut.currentState.overallProgress - 0.5) < 0.001)
    }
}
