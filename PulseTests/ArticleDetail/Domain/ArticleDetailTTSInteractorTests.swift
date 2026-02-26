import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainInteractor TTS Tests")
@MainActor
struct ArticleDetailTTSInteractorTests {
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

    private func createSUT(article: Article? = nil) -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(
            article: article ?? testArticle,
            serviceLocator: serviceLocator
        )
    }

    // MARK: - Initial State

    @Test("Initial TTS state has correct defaults")
    func initialTTSState() {
        let sut = createSUT()
        let state = sut.currentState

        #expect(state.ttsPlaybackState == .idle)
        #expect(state.ttsProgress == 0.0)
        #expect(state.ttsSpeedPreset == .normal)
        #expect(state.isTTSPlayerVisible == false)
    }

    // MARK: - startTTS

    @Test("startTTS calls speak on service and shows player")
    func startTTSSpeaks() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.speakCallCount == 1)
        #expect(mockTTSService.lastSpokenText != nil)
        #expect(mockTTSService.lastSpokenText?.contains(testArticle.title) == true)
        #expect(sut.currentState.isTTSPlayerVisible == true)
    }

    @Test("startTTS uses normal speed rate by default")
    func startTTSUsesDefaultRate() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.lastRate == TTSSpeedPreset.normal.rate)
    }

    @Test("startTTS logs analytics event")
    func startTTSLogsAnalytics() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let ttsEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "tts_started" }
        #expect(ttsEvents.count == 1)
    }

    // MARK: - toggleTTSPlayback

    @Test("toggleTTSPlayback pauses when playing")
    func togglePausesWhenPlaying() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        sut.dispatch(action: .toggleTTSPlayback)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.pauseCallCount == 1)
    }

    @Test("toggleTTSPlayback resumes when paused")
    func toggleResumesWhenPaused() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        mockTTSService.pause()
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        sut.dispatch(action: .toggleTTSPlayback)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.resumeCallCount == 1)
    }

    @Test("toggleTTSPlayback starts when idle")
    func toggleStartsWhenIdle() async throws {
        let sut = createSUT()

        sut.dispatch(action: .toggleTTSPlayback)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.speakCallCount == 1)
    }

    // MARK: - stopTTS

    @Test("stopTTS calls stop on service and hides player")
    func stopTTSStops() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        sut.dispatch(action: .stopTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.stopCallCount == 1)
        #expect(sut.currentState.isTTSPlayerVisible == false)
        #expect(sut.currentState.ttsProgress == 0.0)
    }

    @Test("stopTTS logs analytics event")
    func stopTTSLogsAnalytics() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        sut.dispatch(action: .stopTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let ttsStopEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "tts_stopped" }
        #expect(ttsStopEvents.count == 1)
    }

    // MARK: - cycleTTSSpeed

    @Test("cycleTTSSpeed cycles through presets")
    func cycleTTSSpeed() {
        let sut = createSUT()

        #expect(sut.currentState.ttsSpeedPreset == .normal)

        sut.dispatch(action: .cycleTTSSpeed)
        #expect(sut.currentState.ttsSpeedPreset == .fast)

        sut.dispatch(action: .cycleTTSSpeed)
        #expect(sut.currentState.ttsSpeedPreset == .faster)

        sut.dispatch(action: .cycleTTSSpeed)
        #expect(sut.currentState.ttsSpeedPreset == .fastest)

        sut.dispatch(action: .cycleTTSSpeed)
        #expect(sut.currentState.ttsSpeedPreset == .normal)
    }

    @Test("cycleTTSSpeed restarts speech when playing")
    func cycleTTSSpeedRestartsSpeech() async throws {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let initialSpeakCount = mockTTSService.speakCallCount

        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockTTSService.speakCallCount > initialSpeakCount)
        #expect(mockTTSService.lastRate == TTSSpeedPreset.fast.rate)
    }

    @Test("cycleTTSSpeed logs analytics event")
    func cycleTTSSpeedLogsAnalytics() async throws {
        let sut = createSUT()

        sut.dispatch(action: .cycleTTSSpeed)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let speedEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "tts_speed_changed" }
        #expect(speedEvents.count == 1)
        #expect(speedEvents.first?.parameters?["speed"] as? String == "1.25x")
    }

    // MARK: - State Bindings

    @Test("TTS playback state changes are reflected in domain state")
    func ttsPlaybackStateBindings() {
        let sut = createSUT()

        sut.dispatch(action: .ttsPlaybackStateChanged(.playing))
        #expect(sut.currentState.ttsPlaybackState == .playing)

        sut.dispatch(action: .ttsPlaybackStateChanged(.paused))
        #expect(sut.currentState.ttsPlaybackState == .paused)

        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))
        #expect(sut.currentState.ttsPlaybackState == .idle)
    }

    @Test("TTS progress updates are reflected in domain state")
    func ttsProgressBindings() {
        let sut = createSUT()

        sut.dispatch(action: .ttsProgressUpdated(0.5))
        #expect(sut.currentState.ttsProgress == 0.5)

        sut.dispatch(action: .ttsProgressUpdated(1.0))
        #expect(sut.currentState.ttsProgress == 1.0)
    }

    @Test("TTS player auto-hides when playback finishes")
    func ttsPlayerAutoHidesWhenFinished() {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        #expect(sut.currentState.isTTSPlayerVisible == true)

        sut.dispatch(action: .ttsProgressUpdated(1.0))
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))

        #expect(sut.currentState.isTTSPlayerVisible == false)
    }

    @Test("TTS player stays visible when playback is idle before completion")
    func ttsPlayerRemainsVisibleWhenIdleBeforeCompletion() {
        let sut = createSUT()

        sut.dispatch(action: .startTTS)
        #expect(sut.currentState.isTTSPlayerVisible == true)

        sut.dispatch(action: .ttsProgressUpdated(0.4))
        sut.dispatch(action: .ttsPlaybackStateChanged(.idle))

        #expect(sut.currentState.isTTSPlayerVisible == true)
    }

    // MARK: - Speech Text Building

    @Test("startTTS builds speech text with author")
    func buildsSpeechTextWithAuthor() async throws {
        let article = Article(
            id: "test-tts",
            title: "Test Title",
            description: "Test description.",
            content: "Full content here.",
            author: "Jane Doe",
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let sut = createSUT(article: article)
        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let text = mockTTSService.lastSpokenText ?? ""
        #expect(text.contains("Test Title"))
        #expect(text.contains("Jane Doe"))
        #expect(text.contains("Test description."))
        #expect(text.contains("Full content here."))
    }

    @Test("startTTS handles article without optional fields")
    func buildsSpeechTextMinimal() async throws {
        let article = Article(
            id: "test-minimal",
            title: "Only Title",
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let sut = createSUT(article: article)
        sut.dispatch(action: .startTTS)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        let text = mockTTSService.lastSpokenText ?? ""
        #expect(text.contains("Only Title"))
    }
}
