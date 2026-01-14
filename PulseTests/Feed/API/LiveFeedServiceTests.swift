import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveFeedService Tests")
struct LiveFeedServiceTests {
    let mockLLMService: MockLLMService

    init() {
        mockLLMService = MockLLMService()
    }

    private func createSUT() -> LiveFeedService {
        LiveFeedService(llmService: mockLLMService)
    }

    // MARK: - Model Status Tests

    @Test("isModelReady returns LLM service model loaded state")
    func isModelReady() {
        mockLLMService.isModelLoaded = true
        let sut = createSUT()

        #expect(sut.isModelReady == true)

        mockLLMService.isModelLoaded = false
        let sut2 = createSUT()

        #expect(sut2.isModelReady == false)
    }

    @Test("loadModelIfNeeded skips when model already loaded")
    func loadModelSkipsWhenLoaded() async throws {
        mockLLMService.isModelLoaded = true
        let sut = createSUT()

        try await sut.loadModelIfNeeded()

        // Should not have called loadModel since already loaded
        #expect(mockLLMService.loadModelCallCount == 0)
    }

    @Test("loadModelIfNeeded loads when model not loaded")
    func loadModelWhenNotLoaded() async throws {
        mockLLMService.isModelLoaded = false
        let sut = createSUT()

        try await sut.loadModelIfNeeded()

        #expect(mockLLMService.loadModelCallCount == 1)
    }

    // MARK: - Cached Digest Tests

    @Test("fetchTodaysDigest returns nil when no cached digest")
    func fetchDigestNil() {
        let sut = createSUT()

        let result = sut.fetchTodaysDigest()

        #expect(result == nil)
    }

    @Test("fetchTodaysDigest returns cached digest when from today")
    func fetchDigestToday() {
        let sut = createSUT()

        let todayDigest = DailyDigest(
            summary: "Today's summary",
            generatedAt: Date(),
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(todayDigest)

        let result = sut.fetchTodaysDigest()

        #expect(result != nil)
        #expect(result?.summary == "Today's summary")
    }

    @Test("fetchTodaysDigest returns nil when cached digest is from yesterday")
    func fetchDigestYesterday() {
        let sut = createSUT()

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayDigest = DailyDigest(
            summary: "Yesterday's summary",
            generatedAt: yesterday,
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(yesterdayDigest)

        let result = sut.fetchTodaysDigest()

        #expect(result == nil)
    }

    @Test("fetchTodaysDigest returns nil when cached digest has empty summary")
    func fetchDigestEmptySummary() {
        let sut = createSUT()

        let emptyDigest = DailyDigest(
            summary: "   ",
            generatedAt: Date(),
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(emptyDigest)

        let result = sut.fetchTodaysDigest()

        #expect(result == nil)
    }

    // MARK: - Save Digest Tests

    @Test("saveDigest caches digest with valid summary")
    func saveDigestValid() {
        let sut = createSUT()

        let validDigest = DailyDigest(
            summary: "Valid summary content",
            generatedAt: Date(),
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(validDigest)

        let cached = sut.fetchTodaysDigest()
        #expect(cached != nil)
        #expect(cached?.summary == "Valid summary content")
    }

    @Test("saveDigest does not cache digest with empty summary")
    func saveDigestEmptyNotCached() {
        let sut = createSUT()

        let emptyDigest = DailyDigest(
            summary: "",
            generatedAt: Date(),
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(emptyDigest)

        let cached = sut.fetchTodaysDigest()
        #expect(cached == nil)
    }

    @Test("saveDigest does not cache digest with whitespace-only summary")
    func saveDigestWhitespaceNotCached() {
        let sut = createSUT()

        let whitespaceDigest = DailyDigest(
            summary: "   \n\t  ",
            generatedAt: Date(),
            sourceArticles: Article.mockArticles
        )
        sut.saveDigest(whitespaceDigest)

        let cached = sut.fetchTodaysDigest()
        #expect(cached == nil)
    }

    // MARK: - Cancel Generation Tests

    @Test("cancelGeneration calls LLM service cancelGeneration")
    func cancelGeneration() {
        let sut = createSUT()

        sut.cancelGeneration()

        #expect(mockLLMService.cancelGenerationCallCount == 1)
    }

    // MARK: - Model Status Publisher Tests

    @Test("modelStatusPublisher exposes LLM service publisher")
    func modelStatusPublisher() async {
        let sut = createSUT()
        var cancellables = Set<AnyCancellable>()
        var receivedStatuses: [LLMModelStatus] = []

        sut.modelStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }
            .store(in: &cancellables)

        // The mock should have emitted an initial status
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(!receivedStatuses.isEmpty)
    }
}

// MARK: - LLMInferenceConfig Tests

@Suite("LLMInferenceConfig DailyDigest Tests")
struct LLMInferenceConfigDailyDigestTests {
    @Test("dailyDigest config has correct values")
    func dailyDigestConfig() {
        let config = LLMInferenceConfig.dailyDigest

        #expect(config.maxTokens == 1024)
        #expect(config.temperature == 0.6)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</digest>"))
        #expect(config.stopSequences.contains("\n\n\n"))
        #expect(config.stopSequences.contains("---"))
    }
}
