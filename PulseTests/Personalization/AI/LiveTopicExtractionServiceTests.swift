import Foundation
@testable import Pulse
import Testing

@Suite("LiveTopicExtractionService Tests")
@MainActor
struct LiveTopicExtractionServiceTests {
    @Test("isModelAvailable mirrors the LLM service state")
    func isModelAvailableMirrorsLLM() {
        let mockLLM = MockLLMService()
        let sut = LiveTopicExtractionService(llmService: mockLLM)

        mockLLM.isModelLoaded = false
        #expect(sut.isModelAvailable == false)

        mockLLM.isModelLoaded = true
        #expect(sut.isModelAvailable == true)
    }

    @Test("Extracts and parses tags from a clean LLM response")
    func extractsCleanResponse() async throws {
        let mockLLM = MockLLMService()
        mockLLM.generateResult = .success("ai, machine-learning, technology")
        mockLLM.generateDelay = 0.01
        let sut = LiveTopicExtractionService(llmService: mockLLM)

        let tags = try await sut.extractTopics(title: "Apple unveils M4", summary: nil)
        #expect(tags == ["ai", "machine-learning", "technology"])
    }

    @Test("Sanitizes a noisy LLM response")
    func extractsNoisyResponse() async throws {
        let mockLLM = MockLLMService()
        mockLLM.generateResult = .success("```\nClimate Change, AI, Renewable_Energy\n```")
        mockLLM.generateDelay = 0.01
        let sut = LiveTopicExtractionService(llmService: mockLLM)

        let tags = try await sut.extractTopics(title: "Climate report", summary: nil)
        #expect(Set(tags) == ["climate-change", "ai", "renewable-energy"])
    }

    @Test("Returns empty array when LLM produces no usable tags")
    func emptyOnUnparseable() async throws {
        let mockLLM = MockLLMService()
        mockLLM.generateResult = .success("? ! .")
        mockLLM.generateDelay = 0.01
        let sut = LiveTopicExtractionService(llmService: mockLLM)

        let tags = try await sut.extractTopics(title: "Test", summary: nil)
        #expect(tags.isEmpty)
    }

    @Test("Propagates LLM errors")
    func propagatesLLMErrors() async {
        let mockLLM = MockLLMService()
        mockLLM.generateResult = .failure(LLMError.memoryPressure)
        mockLLM.generateDelay = 0.01
        let sut = LiveTopicExtractionService(llmService: mockLLM)

        // `#expect(throws:)` would require `sut` to be `Sendable` (the macro
        // crosses an actor boundary); use a manual catch instead.
        var thrown: Error?
        do {
            _ = try await sut.extractTopics(title: "Test", summary: nil)
        } catch {
            thrown = error
        }
        #expect(thrown is LLMError)
    }
}
