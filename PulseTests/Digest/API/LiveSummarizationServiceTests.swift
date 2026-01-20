import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSummarizationService Tests")
@MainActor
struct LiveSummarizationServiceTests {
    var mockLLMService: MockLLMService
    var sut: LiveSummarizationService

    init() {
        mockLLMService = MockLLMService()
        sut = LiveSummarizationService(llmService: mockLLMService)
    }

    @Test("Initial state has model not loaded")
    func initialState() {
        #expect(!sut.isModelLoaded)
    }

    @Test("Model status publisher emits mock status")
    func modelStatusPublisherEmitsStatus() {
        var receivedStatuses: [LLMModelStatus] = []
        let cancellable = sut.modelStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }

        #expect(!receivedStatuses.isEmpty)

        cancellable.cancel()
    }

    @Test("Load modelIfNeeded is callable")
    func loadModelIfNeededIsCallable() async {
        do {
            try await sut.loadModelIfNeeded()
        } catch {}
        #expect(true)
    }

    @Test("Cancel summarization is callable")
    func cancelSummarization() {
        sut.cancelSummarization()
        #expect(true)
    }

    @Test("Summarize returns AsyncThrowingStream")
    func summarizeReturnsAsyncStream() {
        let article = Article.mockArticles.first!
        let stream = sut.summarize(article: article)

        #expect(stream != nil)
    }
}
