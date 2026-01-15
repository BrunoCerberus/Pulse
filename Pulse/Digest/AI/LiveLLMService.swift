import Combine
import Foundation

/// Live implementation of LLMService using llama.cpp
final class LiveLLMService: LLMService {
    private let modelManager: LLMModelManager
    private let modelStatusSubject = CurrentValueSubject<LLMModelStatus, Never>(.notLoaded)
    private var generationTask: Task<Void, Never>?

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        modelStatusSubject.eraseToAnyPublisher()
    }

    var isModelLoaded: Bool {
        if case .ready = modelStatusSubject.value { return true }
        return false
    }

    init(modelManager: LLMModelManager = .shared) {
        self.modelManager = modelManager
    }

    func loadModel() async throws {
        modelStatusSubject.send(.loading(progress: 0.0))

        do {
            try await modelManager.loadModel { [weak self] progress in
                self?.modelStatusSubject.send(.loading(progress: progress))
            }
            modelStatusSubject.send(.ready)
        } catch {
            modelStatusSubject.send(.error(error.localizedDescription))
            throw error
        }
    }

    func unloadModel() async {
        await modelManager.unloadModel()
        modelStatusSubject.send(.notLoaded)
    }

    func generate(
        prompt: String,
        systemPrompt: String?,
        config: LLMInferenceConfig
    ) -> AnyPublisher<String, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(LLMError.serviceUnavailable))
                return
            }

            Task {
                do {
                    var result = ""
                    for try await token in self.generateStream(
                        prompt: prompt,
                        systemPrompt: systemPrompt,
                        config: config
                    ) {
                        result += token
                    }
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func generateStream(
        prompt: String,
        systemPrompt: String?,
        config: LLMInferenceConfig
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            self.generationTask = Task {
                do {
                    // Check if model is loaded
                    guard self.modelManager.modelIsLoaded else {
                        throw LLMError.modelNotLoaded
                    }

                    // Get the token stream from the manager
                    let tokens = self.modelManager.generate(
                        prompt: prompt,
                        systemPrompt: systemPrompt ?? LLMModelManager.defaultSystemPrompt,
                        maxTokens: config.maxTokens,
                        temperature: config.temperature,
                        topP: config.topP,
                        stopSequences: config.stopSequences
                    )

                    for try await token in tokens {
                        if Task.isCancelled { break }
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        modelManager.cancelGeneration()
    }
}
