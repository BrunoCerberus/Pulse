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

        // Cycle speed — this restarts speech
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

    @Test("cycleTTSSpeed keeps player visible even when progress was at 1.0")
    func keepPlayerVisibleAtFullProgress() async throws {
        let sut = createSUT()

        // Start TTS and set progress to 1.0 (last word being spoken)
        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.simulateProgress(1.0)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Cycle speed — should reset progress and keep player visible
        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Even if idle is dispatched, player should stay visible (progress was reset)
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))

        #expect(sut.currentState.isTTSPlayerVisible == true)
        #expect(sut.currentState.ttsProgress == 0.0)
    }
}
