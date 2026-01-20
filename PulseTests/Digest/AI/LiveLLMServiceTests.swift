import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveLLMService Tests")
@MainActor
struct LiveLLMServiceTests {
    let mockModelManager: MockLLMModelManager
    let sut: LiveLLMService

    init() {
        mockModelManager = MockLLMModelManager()
        sut = LiveLLMService(modelManager: mockModelManager)
    }

    // MARK: - Model Status Publisher Tests

    @Test("Model status publisher emits notLoaded initially")
    func initialModelStatus() async throws {
        var capturedStatuses: [LLMModelStatus] = []
        var cancellables = Set<AnyCancellable>()

        sut.modelStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        #expect(sut.isModelLoaded == false)
    }

    @Test("Model status publisher emits loading and ready on successful load")
    func modelStatusProgressOnLoad() async throws {
        var capturedStatuses: [LLMModelStatus] = []
        var cancellables = Set<AnyCancellable>()

        sut.modelStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        mockModelManager.shouldSucceed = true

        try await sut.loadModel()

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(sut.isModelLoaded == true)
        // Should have emitted: loading(0.0), loading(progress), ..., ready
        let hasLoadingStatus = capturedStatuses.contains { status in
            if case .loading = status { return true }
            return false
        }
        #expect(hasLoadingStatus)
    }

    @Test("Model status publisher emits error on load failure")
    func modelStatusErrorOnLoadFailure() async throws {
        var capturedStatuses: [LLMModelStatus] = []
        var cancellables = Set<AnyCancellable>()

        sut.modelStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        mockModelManager.shouldSucceed = false

        do {
            try await sut.loadModel()
            #expect(Bool(false), "Should have thrown error")
        } catch {
            try await Task.sleep(nanoseconds: TestWaitDuration.standard)
            let hasErrorStatus = capturedStatuses.contains { status in
                if case .error = status { return true }
                return false
            }
            #expect(hasErrorStatus)
        }
    }

    @Test("isModelLoaded returns true after successful load")
    func isModelLoadedAfterLoad() async throws {
        #expect(sut.isModelLoaded == false)

        mockModelManager.shouldSucceed = true
        try await sut.loadModel()

        #expect(sut.isModelLoaded == true)
    }

    @Test("isModelLoaded returns false after unload")
    func isModelLoadedAfterUnload() async throws {
        mockModelManager.shouldSucceed = true
        try await sut.loadModel()
        #expect(sut.isModelLoaded == true)

        await sut.unloadModel()
        #expect(sut.isModelLoaded == false)
    }

    // MARK: - Load Model Tests

    @Test("loadModel updates status through publisher")
    func loadModelPublishesStatus() async throws {
        var statusSequence: [LLMModelStatus] = []
        var cancellables = Set<AnyCancellable>()

        sut.modelStatusPublisher
            .sink { status in
                statusSequence.append(status)
            }
            .store(in: &cancellables)

        mockModelManager.shouldSucceed = true
        try await sut.loadModel()

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(statusSequence.count > 0)
        // Last status should be ready
        if let lastStatus = statusSequence.last {
            if case .ready = lastStatus {
                // Expected
            } else {
                #expect(Bool(false), "Expected ready status, got \(lastStatus)")
            }
        }
    }

    @Test("loadModel throws error when manager fails")
    func loadModelThrowsOnManagerFailure() async throws {
        mockModelManager.shouldSucceed = false

        do {
            try await sut.loadModel()
            #expect(Bool(false), "Should have thrown")
        } catch let error as LLMError {
            #expect(error == .modelLoadFailed("Mock load failed"))
        }
    }

    // MARK: - Unload Model Tests

    @Test("unloadModel sets status to notLoaded")
    func unloadModelStatus() async throws {
        var capturedStatuses: [LLMModelStatus] = []
        var cancellables = Set<AnyCancellable>()

        sut.modelStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        mockModelManager.shouldSucceed = true
        try await sut.loadModel()

        await sut.unloadModel()

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        // Should contain notLoaded status after unload
        let hasNotLoadedAfterUnload = capturedStatuses.suffix(2).contains { status in
            if case .notLoaded = status { return true }
            return false
        }
        #expect(hasNotLoadedAfterUnload)
    }

    // MARK: - Generation Tests

    @Test("generate returns complete result as publisher")
    func generatePublisher() async throws {
        mockModelManager.shouldSucceed = true
        mockModelManager.generationResult = "Test generation result"

        try await sut.loadModel()

        var capturedResult: String?
        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        let config = LLMInferenceConfig.default

        sut.generate(
            prompt: "Test prompt",
            systemPrompt: "Test system",
            config: config
        )
        .sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    capturedError = error
                }
            },
            receiveValue: { result in
                capturedResult = result
            }
        )
        .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.long)

        #expect(capturedResult != nil)
        #expect(capturedError == nil)
    }

    @Test("generate fails when model not loaded")
    func generateWithoutModel() async throws {
        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        let config = LLMInferenceConfig.default

        sut.generate(
            prompt: "Test prompt",
            systemPrompt: nil,
            config: config
        )
        .sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    capturedError = error
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError is LLMError)
    }

    // MARK: - Stream Generation Tests

    @Test("generateStream produces tokens sequentially")
    async func testGenerateStreamTokens() throws {
        mockModelManager.shouldSucceed = true
        mockModelManager.generationResult = "Test"

        try await sut.loadModel()

        var tokens: [String] = []
        let config = LLMInferenceConfig.default

        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: nil,
            config: config
        )

        for try await token in stream {
            tokens.append(token)
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(tokens.count > 0)
    }

    @Test("generateStream fails when model not loaded")
    async func testGenerateStreamWithoutModel() throws {
        var capturedError: Error?
        let config = LLMInferenceConfig.default

        do {
            let stream = sut.generateStream(
                prompt: "Test",
                systemPrompt: nil,
                config: config
            )

            for try await _ in stream {
                // Intentionally empty
            }
        } catch {
            capturedError = error
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError is LLMError)
    }

    @Test("generateStream respects custom system prompt")
    async func testGenerateStreamCustomSystemPrompt() throws {
        mockModelManager.shouldSucceed = true
        mockModelManager.generationResult = "Response"

        try await sut.loadModel()

        let customSystemPrompt = "You are a test assistant"
        var capturedSystemPrompt: String?

        mockModelManager.capturedSystemPrompt = nil
        mockModelManager.onGenerate = { systemPrompt in
            capturedSystemPrompt = systemPrompt
        }

        let config = LLMInferenceConfig.default
        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: customSystemPrompt,
            config: config
        )

        for try await _ in stream {
            // Intentionally empty
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedSystemPrompt != nil)
    }

    @Test("generateStream uses default system prompt when nil")
    async func testGenerateStreamDefaultSystemPrompt() throws {
        mockModelManager.shouldSucceed = true
        mockModelManager.generationResult = "Response"

        try await sut.loadModel()

        var capturedSystemPrompt: String?
        mockModelManager.onGenerate = { systemPrompt in
            capturedSystemPrompt = systemPrompt
        }

        let config = LLMInferenceConfig.default
        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: nil,
            config: config
        )

        for try await _ in stream {
            // Intentionally empty
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedSystemPrompt == LLMModelManager.defaultSystemPrompt)
    }

    // MARK: - Cancellation Tests

    @Test("cancelGeneration stops ongoing generation")
    async func testCancelGeneration() throws {
        mockModelManager.shouldSucceed = true
        mockModelManager.generationResult = "Long response that takes time"

        try await sut.loadModel()

        let config = LLMInferenceConfig.default
        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: nil,
            config: config
        )

        sut.cancelGeneration()

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(mockModelManager.cancelGenerationWasCalled)
    }

    // MARK: - Configuration Tests

    @Test("generate respects max tokens from config")
    async func testGenerateRespectMaxTokens() throws {
        mockModelManager.shouldSucceed = true
        var capturedMaxTokens: Int?

        mockModelManager.onGenerate = { _ in
            capturedMaxTokens = mockModelManager.lastMaxTokens
        }

        try await sut.loadModel()

        let config = LLMInferenceConfig(
            maxTokens: 512,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: []
        )

        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: nil,
            config: config
        )

        for try await _ in stream {
            // Intentionally empty
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedMaxTokens == 512)
    }

    @Test("generate respects temperature from config")
    async func testGenerateRespectTemperature() async throws {
        mockModelManager.shouldSucceed = true
        var capturedTemperature: Float?

        mockModelManager.onGenerate = { _ in
            capturedTemperature = mockModelManager.lastTemperature
        }

        try await sut.loadModel()

        let config = LLMInferenceConfig(
            maxTokens: 1024,
            temperature: 0.3,
            topP: 0.95,
            stopSequences: []
        )

        let stream = sut.generateStream(
            prompt: "Test",
            systemPrompt: nil,
            config: config
        )

        for try await _ in stream {
            // Intentionally empty
        }

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedTemperature == 0.3)
    }
}

// MARK: - Mock LLM Model Manager

final class MockLLMModelManager: @unchecked Sendable {
    var shouldSucceed = true
    var generationResult = "Mock generation result"
    var lastMaxTokens: Int?
    var lastTemperature: Float?
    var lastTopP: Float?
    var capturedSystemPrompt: String?
    var cancelGenerationWasCalled = false
    var onGenerate: ((String) -> Void)?

    var modelIsLoaded: Bool = false

    func loadModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        progressHandler(0.0)

        for progress in stride(from: 0.1, through: 1.0, by: 0.3) {
            progressHandler(progress)
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        if shouldSucceed {
            modelIsLoaded = true
        } else {
            throw LLMError.modelLoadFailed("Mock load failed")
        }
    }

    func unloadModel() async {
        modelIsLoaded = false
    }

    func cancelGeneration() {
        cancelGenerationWasCalled = true
    }

    func generate(
        prompt _: String,
        systemPrompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        stopSequences _: [String]
    ) -> AsyncThrowingStream<String, Error> {
        lastMaxTokens = maxTokens
        lastTemperature = temperature
        lastTopP = topP
        capturedSystemPrompt = systemPrompt
        onGenerate?(systemPrompt)

        return AsyncThrowingStream { continuation in
            Task {
                if shouldSucceed {
                    continuation.yield(generationResult)
                    continuation.finish()
                } else {
                    continuation.finish(throwing: LLMError.generationFailed("Mock error"))
                }
            }
        }
    }
}
