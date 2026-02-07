import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveLLMService Tests")
struct LiveLLMServiceTests {
    @Test("LiveLLMService can be instantiated")
    func canBeInstantiated() {
        let service = LiveLLMService()
        #expect(service is LLMService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveLLMService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelLoaded returns false initially")
    func isModelLoadedReturnsFalseInitially() {
        let service = LiveLLMService()
        #expect(service.isModelLoaded == false)
    }

    @Test("generate returns correct publisher type")
    func generateReturnsCorrectType() {
        let service = LiveLLMService()
        let publisher = service.generate(prompt: "test", systemPrompt: nil, config: .default)
        let typeCheck: AnyPublisher<String, Error> = publisher
        #expect(typeCheck is AnyPublisher<String, Error>)
    }

    @Test("generateStream returns correct type")
    func generateStreamReturnsCorrectType() {
        let service = LiveLLMService()
        let stream = service.generateStream(prompt: "test", systemPrompt: nil, config: .default)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }

    @Test("cancelGeneration can be called safely")
    func cancelGenerationCanBeCalledSafely() {
        let service = LiveLLMService()
        service.cancelGeneration()
        #expect(service.isModelLoaded == false)
    }
}
