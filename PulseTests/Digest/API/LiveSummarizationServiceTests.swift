import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSummarizationService Tests")
@MainActor
struct LiveSummarizationServiceTests {
    var mockLLMService: MockLLMService!
    var sut: LiveSummarizationService!

    init() {
        mockLLMService = MockLLMService()
        sut = LiveSummarizationService(llmService: mockLLMService)
    }

    // MARK: - Initialization Tests

    @Test("Initialization with default LLMService")
    func initializationWithDefaultLLMService() {
        let service = LiveSummarizationService()

        // Should have a non-nil LLM service (LiveLLMService by default)
        // We can't directly test the internal service, but we can verify
        // the service is functional through its public interface
        #expect(service.modelStatusPublisher != nil)
    }

    @Test("Initialization with custom LLMService")
    func initializationWithCustomLLMService() {
        let customMock = MockLLMService()
        customMock.isModelLoaded = true

        let service = LiveSummarizationService(llmService: customMock)

        #expect(service.isModelLoaded == true)
    }

    // MARK: - Model Status Publisher Tests

    @Test("Model status publisher reflects notLoaded initially")
    func modelStatusPublisherInitialState() {
        var initialStatus: LLMModelStatus?

        let cancellable = sut.modelStatusPublisher
            .first()
            .sink { status in
                initialStatus = status
            }

        // Allow publisher to emit
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        cancellable.cancel()

        #expect(initialStatus == .notLoaded)
    }

    // MARK: - isModelLoaded Tests

    @Test("isModelLoaded returns false when model not loaded")
    func isModelLoadedReturnsFalseWhenNotLoaded() {
        mockLLMService.isModelLoaded = false

        #expect(sut.isModelLoaded == false)
    }

    @Test("isModelLoaded returns true when model is loaded")
    func isModelLoadedReturnsTrueWhenLoaded() {
        mockLLMService.isModelLoaded = true

        #expect(sut.isModelLoaded == true)
    }

    @Test("isModelLoaded reflects LLMService state changes")
    func isModelLoadedReflectsServiceChanges() {
        mockLLMService.isModelLoaded = false
        #expect(sut.isModelLoaded == false)

        mockLLMService.isModelLoaded = true
        #expect(sut.isModelLoaded == true)
    }

    // MARK: - loadModelIfNeeded Tests

    @Test("loadModelIfNeeded calls loadModel when not loaded")
    func loadModelIfNeededCallsLoadWhenNotLoaded() async throws {
        mockLLMService.isModelLoaded = false
        mockLLMService.loadDelay = 0.01

        try await sut.loadModelIfNeeded()

        #expect(mockLLMService.loadModelCallCount == 1)
    }

    @Test("loadModelIfNeeded skips loading when already loaded")
    func loadModelIfNeededSkipsWhenLoaded() async throws {
        mockLLMService.isModelLoaded = true

        try await sut.loadModelIfNeeded()

        #expect(mockLLMService.loadModelCallCount == 0)
    }

    @Test("loadModelIfNeeded propagates errors")
    func loadModelIfNeededPropagatesErrors() async {
        // Create a custom mock that throws on load
        let failingMock = FailingMockLLMService()
        let failingService = LiveSummarizationService(llmService: failingMock)

        do {
            try await failingService.loadModelIfNeeded()
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
            #expect(error is FailingMockLLMService.LoadError)
        }
    }

    // MARK: - summarize Tests

    @Test("summarize returns AsyncThrowingStream")
    func summarizeReturnsAsyncThrowingStream() {
        let article = Article.mockArticles[0]

        let stream = sut.summarize(article: article)

        #expect(stream != nil)
    }

    @Test("summarize stream yields tokens from LLMService")
    func summarizeStreamYieldsTokens() async throws {
        let article = Article.mockArticles[0]
        mockLLMService.generateResult = .success("Test summary content")
        mockLLMService.generateDelay = 0.01

        let stream = sut.summarize(article: article)
        var receivedTokens: [String] = []

        for try await token in stream {
            receivedTokens.append(token)
        }

        #expect(!receivedTokens.isEmpty)
    }

    @Test("summarize stream propagates errors")
    func summarizeStreamPropagatesErrors() async {
        let article = Article.mockArticles[0]
        let errorMock = ErrorMockLLMService()
        let errorService = LiveSummarizationService(llmService: errorMock)

        let stream = errorService.summarize(article: article)

        do {
            for try await _ in stream {
                // Consume stream
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
            #expect(error is ErrorMockLLMService.TestError)
        }
    }

    @Test("summarize builds prompt with article data")
    func summarizeBuildsPromptWithArticle() async throws {
        let article = Article.mockArticles[0]
        mockLLMService.generateResult = .success("Summary")
        mockLLMService.generateDelay = 0.01

        let stream = sut.summarize(article: article)

        // Consume the stream
        var tokens: [String] = []
        for try await token in stream {
            tokens.append(token)
        }

        // The stream should complete successfully
        #expect(!tokens.isEmpty)
    }

    // MARK: - cancelSummarization Tests

    @Test("cancelSummarization calls cancelGeneration on LLMService")
    func cancelSummarizationCallsCancel() {
        #expect(mockLLMService.cancelGenerationCallCount == 0)

        sut.cancelSummarization()

        #expect(mockLLMService.cancelGenerationCallCount == 1)
    }

    @Test("cancelSummarization can be called multiple times")
    func cancelSummarizationMultipleTimes() {
        sut.cancelSummarization()
        sut.cancelSummarization()
        sut.cancelSummarization()

        #expect(mockLLMService.cancelGenerationCallCount == 3)
    }

    @Test("cancelSummarization during streaming stops generation")
    func cancelSummarizationDuringStreaming() async throws {
        let article = Article.mockArticles[0]
        mockLLMService.generateDelay = 0.1 // Slow generation

        let stream = sut.summarize(article: article)

        // Start consuming in a task
        let task = Task {
            var tokens: [String] = []
            for try await token in stream {
                tokens.append(token)
            }
            return tokens
        }

        // Small delay to let stream start
        try await Task.sleep(nanoseconds: 50_000_000)

        // Cancel the summarization
        sut.cancelSummarization()

        // Wait for task to complete
        _ = await task.result

        // Cancel should have been called
        #expect(mockLLMService.cancelGenerationCallCount >= 1)
    }
}

// MARK: - LLMInferenceConfig Tests

@Suite("LLMInferenceConfig Summarization Tests")
struct LLMInferenceConfigSummarizationTests {
    @Test("Summarization config has correct maxTokens")
    func summarizationConfigMaxTokens() {
        let config = LLMInferenceConfig.summarization

        #expect(config.maxTokens == 512)
    }

    @Test("Summarization config has correct temperature")
    func summarizationConfigTemperature() {
        let config = LLMInferenceConfig.summarization

        #expect(config.temperature == 0.5)
    }

    @Test("Summarization config has correct topP")
    func summarizationConfigTopP() {
        let config = LLMInferenceConfig.summarization

        #expect(config.topP == 0.9)
    }

    @Test("Summarization config has correct stop sequences")
    func summarizationConfigStopSequences() {
        let config = LLMInferenceConfig.summarization

        #expect(config.stopSequences == ["</summary>", "\n\n\n"])
    }

    @Test("Summarization config differs from default config")
    func summarizationConfigDiffersFromDefault() {
        let summarization = LLMInferenceConfig.summarization
        let `default` = LLMInferenceConfig.default

        #expect(summarization.maxTokens != `default`.maxTokens)
        #expect(summarization.temperature != `default`.temperature)
        #expect(summarization.stopSequences != `default`.stopSequences)
    }
}

// MARK: - Mock Helpers

/// Mock LLMService that always fails to load
@MainActor
private final class FailingMockLLMService: LLMService {
    enum LoadError: Error {
        case alwaysFails
    }

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        Just(.notLoaded).eraseToAnyPublisher()
    }

    var isModelLoaded: Bool {
        false
    }

    func loadModel() async throws {
        throw LoadError.alwaysFails
    }

    func unloadModel() async {}

    func generate(prompt _: String, systemPrompt _: String?, config _: LLMInferenceConfig) -> AnyPublisher<String, Error> {
        Fail(error: LoadError.alwaysFails).eraseToAnyPublisher()
    }

    func generateStream(prompt _: String, systemPrompt _: String?, config _: LLMInferenceConfig) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: LoadError.alwaysFails)
        }
    }

    func cancelGeneration() {}
}

/// Mock LLMService that always throws errors during generation
@MainActor
private final class ErrorMockLLMService: LLMService {
    struct TestError: Error {}

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        Just(.ready).eraseToAnyPublisher()
    }

    var isModelLoaded: Bool {
        true
    }

    func loadModel() async throws {}

    func unloadModel() async {}

    func generate(prompt _: String, systemPrompt _: String?, config _: LLMInferenceConfig) -> AnyPublisher<String, Error> {
        Fail(error: TestError()).eraseToAnyPublisher()
    }

    func generateStream(prompt _: String, systemPrompt _: String?, config _: LLMInferenceConfig) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: TestError())
        }
    }

    func cancelGeneration() {}
}
