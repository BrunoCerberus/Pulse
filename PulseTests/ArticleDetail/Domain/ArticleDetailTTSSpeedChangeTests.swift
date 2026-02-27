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

        // Cycle speed — this restarts speech via stop() + speak()
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Simulate the stale didCancel from the old utterance
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

    @Test("cycleTTSSpeed suppresses idle from stop then allows playing through")
    func suppressesIdleThenAllowsPlaying() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.simulateProgress(1.0)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Cycle speed — sets isRestartingForSpeedChange flag
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Simulate the full restart sequence: .idle (from stop), .playing (from speak), .idle (from didCancel)
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))
        #expect(sut.currentState.isTTSPlayerVisible == true, "First .idle (from stop) should be suppressed")

        sut.dispatch(action: .ttsPlaybackStateChanged(.playing))
        #expect(sut.currentState.isTTSPlayerVisible == true, ".playing should clear the flag")

        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))
        #expect(sut.currentState.isTTSPlayerVisible == true, "Second .idle (from didCancel) should not auto-hide since progress was reset")
    }

    @Test("cycleTTSSpeed player auto-hides normally after speed change completes")
    func autoHidesAfterSpeedChangeCompletes() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Cycle speed — restarts speech
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Simulate restart completing: .idle suppressed, .playing clears flag
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))
        sut.dispatch(action: .ttsPlaybackStateChanged(.playing))

        // Now speech plays to completion naturally
        sut.dispatch(action: .ttsProgressUpdated(1.0))
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))

        // Player should auto-hide normally after natural finish
        #expect(sut.currentState.isTTSPlayerVisible == false)
    }
}
