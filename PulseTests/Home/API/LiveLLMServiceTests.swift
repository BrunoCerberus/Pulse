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
        // Compile-time protocol conformance check
        let _: any LLMService = service
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveLLMService()
        let publisher = service.modelStatusPublisher
        // Type annotation verifies publisher type at compile time
        let _: AnyPublisher<LLMModelStatus, Never> = publisher
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
        // Type annotation verifies publisher type at compile time
        let _: AnyPublisher<String, Error> = publisher
    }

    @Test("generateStream returns correct type")
    func generateStreamReturnsCorrectType() {
        let service = LiveLLMService()
        let stream = service.generateStream(prompt: "test", systemPrompt: nil, config: .default)
        // Type annotation verifies stream type at compile time
        let _: AsyncThrowingStream<String, Error> = stream
    }

    @Test("cancelGeneration can be called safely")
    func cancelGenerationCanBeCalledSafely() {
        let service = LiveLLMService()
        service.cancelGeneration()
        #expect(service.isModelLoaded == false)
    }
}
