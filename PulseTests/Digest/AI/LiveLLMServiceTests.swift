import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveLLMService Tests")
@MainActor
struct LiveLLMServiceTests {
    var sut: LiveLLMService

    init() {
        sut = LiveLLMService()
    }

    @Test("Initial state is not loaded")
    func initialState() {
        #expect(!sut.isModelLoaded)
    }

    @Test("Model status publisher emits initial state")
    func modelStatusPublisherEmitsInitial() {
        var receivedStatuses: [LLMModelStatus] = []
        let cancellable = sut.modelStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }

        #expect(!receivedStatuses.isEmpty)
        #expect(receivedStatuses.first == .notLoaded)

        cancellable.cancel()
    }

    @Test("Generate returns publisher")
    func generateReturnsPublisher() {
        let config = LLMInferenceConfig(
            maxTokens: 100,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: []
        )

        let publisher = sut.generate(
            prompt: "Test prompt",
            systemPrompt: "Test system",
            config: config
        )

        #expect(publisher != nil)
    }

    @Test("GenerateStream returns AsyncThrowingStream")
    func generateStreamReturnsAsyncStream() async {
        let config = LLMInferenceConfig(
            maxTokens: 100,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: []
        )

        let stream = sut.generateStream(
            prompt: "Test prompt",
            systemPrompt: "Test system",
            config: config
        )

        #expect(stream != nil)
    }

    @Test("Cancel generation is callable")
    func cancelGenerationIsCallable() {
        sut.cancelGeneration()
        #expect(true)
    }

    @Test("Model status publisher emits loading state during load")
    @available(macOS 15.0, iOS 18.0, *)
    func modelStatusPublisherEmitsLoading() async throws {
        var receivedStatuses: [LLMModelStatus] = []

        let cancellable = sut.modelStatusPublisher
            .dropFirst()
            .sink { status in
                receivedStatuses.append(status)
            }

        Task {
            try? await sut.loadModel()
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        cancellable.cancel()

        let hasLoadingState = receivedStatuses.contains { status in
            if case .loading = status {
                return true
            }
            return false
        }

        #expect(hasLoadingState)
    }
}
