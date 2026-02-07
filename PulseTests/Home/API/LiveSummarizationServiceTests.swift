import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSummarizationService Tests")
struct LiveSummarizationServiceTests {
    @Test("LiveSummarizationService can be instantiated")
    func canBeInstantiated() {
        let service = LiveSummarizationService()
        #expect(service is SummarizationService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveSummarizationService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelLoaded returns false when model not loaded")
    func isModelLoadedReturnsFalse() {
        let service = LiveSummarizationService()
        #expect(service.isModelLoaded == false)
    }

    @Test("summarize returns AsyncThrowingStream")
    func summarizeReturnsStream() throws {
        let service = LiveSummarizationService()
        let article = try #require(Article.mockArticles.first)
        let stream = service.summarize(article: article)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }

    @Test("cancelSummarization calls LLM service")
    func cancelSummarizationCallsLLMService() {
        let mockLLMService = MockLLMService()
        let service = LiveSummarizationService(llmService: mockLLMService)
        service.cancelSummarization()
        #expect(mockLLMService.cancelGenerationCallCount == 1)
    }
}
