import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetail TTS Speed Change Player Visibility Tests")
@MainActor
struct ArticleDetailTTSSpeedChangeTests {
    let mockStorageService: MockStorageService
    let mockTTSService: MockTextToSpeechService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let testArticle: Article

    init() {
        mockStorageService = MockStorageService()
        mockTTSService = MockTextToSpeechService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(TextToSpeechService.self, instance: mockTTSService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        testArticle = Article.mockArticles[0]
    }

    private func createSUT() -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(
            article: testArticle,
            serviceLocator: serviceLocator
        )
    }

    @Test("cycleTTSSpeed keeps player visible when stale cancel callback fires")
    func keepPlayerVisibleOnStaleCancel() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.isTTSPlayerVisible == true)

        mockTTSService.simulateProgress(0.5)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Cycle speed — this restarts speech via stop() + speak(),
        // increments generation and re-subscribes
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Simulate the stale didCancel from the old utterance —
        // generation counter causes these to be discarded
        mockTTSService.simulateStaleCancelCallback()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Player bar must remain visible
        #expect(sut.currentState.isTTSPlayerVisible == true)
        #expect(sut.currentState.ttsSpeedPreset == .fast)
    }

    @Test("cycleTTSSpeed resets progress to prevent auto-hide")
    func resetsProgressOnSpeedChange() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.simulateProgress(0.95)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.ttsProgress == 0.95)

        // Cycle speed — progress should reset
        sut.dispatch(action: .cycleTTSSpeed)

        #expect(sut.currentState.ttsProgress == 0.0)
        #expect(sut.currentState.isTTSPlayerVisible == true)
    }

    @Test("Stale progress callbacks after speed change are ignored")
    func staleProgressIgnoredAfterSpeedChange() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.simulateProgress(0.5)
        try await waitForStateUpdate(duration: TestWaitDuration.short)
        #expect(sut.currentState.ttsProgress == 0.5)

        // Cycle speed — increments generation
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Progress is reset to 0.0 by cycleTTSSpeed, then re-subscription
        // picks up the current .playing state. Stale callbacks from old
        // generation are discarded, so progress stays at 0.0.
        #expect(sut.currentState.ttsProgress == 0.0)
        #expect(sut.currentState.ttsPlaybackState == .playing)
    }

    @Test("cycleTTSSpeed player auto-hides normally after speed change completes")
    func autoHidesAfterSpeedChangeCompletes() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Cycle speed — restarts speech with new generation
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Now speech plays to completion naturally
        mockTTSService.simulateProgress(1.0)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.simulateFinished()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Player should auto-hide normally after natural finish
        #expect(sut.currentState.isTTSPlayerVisible == false)
    }
}
