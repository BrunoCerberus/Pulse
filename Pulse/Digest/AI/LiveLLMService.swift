import Combine
import EntropyCore
import Foundation
import os

/// Live implementation of LLMService using SwiftLlama (llama.cpp) for on-device LLM inference.
///
/// This service manages the lifecycle of on-device LLM inference, including:
/// - Model loading with progress tracking
/// - Streaming text generation via `AsyncThrowingStream`
/// - Generation cancellation
/// - Model unloading for memory management
///
/// ## Thread Safety
/// All operations are designed to be called from the main actor context.
/// Background inference is handled internally with proper continuation management.
final class LiveLLMService: LLMService, @unchecked Sendable {
    private let modelManager: LLMModelManager
    private let modelStatusSubject = CurrentValueSubject<LLMModelStatus, Never>(.notLoaded)

    /// Streaming generation task (`generateStream`). Guarded by `lock` (H4) —
    /// it's written from the stream-build closure (arbitrary executor) and read
    /// from `cancelGeneration()` (any thread).
    private var generationTask: Task<Void, Never>?

    /// Non-streaming generation task (`generate` / `Future`). Stored so a
    /// torn-down subscription can cancel the in-flight inference on the shared
    /// model instead of leaking it (H5). Guarded by `lock`.
    private var futureGenerationTask: Task<Void, Never>?

    /// Async-safe lock protecting `generationTask` and `futureGenerationTask`.
    private let lock = OSAllocatedUnfairLock()

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
        sendStatus(.loading(progress: 0.0))

        do {
            try await modelManager.loadModel { [weak self] progress in
                self?.sendStatus(.loading(progress: progress))
            }
            sendStatus(.ready)
        } catch {
            sendStatus(.error(error.localizedDescription))
            throw error
        }
    }

    func unloadModel() async {
        await modelManager.unloadModel()
        sendStatus(.notLoaded)
    }

    private func sendStatus(_ status: LLMModelStatus) {
        // M12: always dispatch async to main so status events stay FIFO.
        // The previous synchronous main-thread fast-path could deliver an
        // on-main terminal `.ready`/`.error` BEFORE an off-main `.loading(_)`
        // that was queued earlier, reordering the status stream.
        DispatchQueue.main.async { [weak self] in
            self?.modelStatusSubject.send(status)
        }
    }

    // NOTE: This `AnyPublisher` (buffered) form currently has no in-app callers
    // (every consumer uses `generateStream`); it's kept because removing it
    // would touch the `LLMService` protocol. It's still made cancellation-safe
    // (H5): the inference `Task` is stored under the lock and cancelled both by
    // `cancelGeneration()` and by the publisher's own teardown.
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

            let stream = UncheckedSendableBox(value: self.generateStream(
                prompt: prompt,
                systemPrompt: systemPrompt,
                config: config
            ))
            let promise = UncheckedSendableBox(value: promise)

            // H4/H5: store the task under the lock so teardown can cancel it.
            self.lock.withLock {
                self.futureGenerationTask = Task {
                    do {
                        var result = ""
                        for try await token in stream.value {
                            if Task.isCancelled { break }
                            result += token
                        }
                        promise.value(.success(result))
                    } catch {
                        promise.value(.failure(error))
                    }
                }
            }
        }
        // H5: a cancelled/torn-down subscription must stop the inference running
        // on the shared model — not just abandon the publisher.
        .handleEvents(receiveCancel: { [weak self] in
            self?.cancelFutureGeneration()
        })
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

            // H4: assign the streaming task under the lock.
            self.lock.withLock {
                self.generationTask = Task {
                    do {
                        // Check if model is loaded
                        guard self.modelManager.modelIsLoaded else {
                            throw LLMError.modelNotLoaded
                        }

                        // Get the token stream from the manager. L9: forward the
                        // per-call sampling parameters so e.g. topic extraction
                        // runs at its intended low temperature instead of the
                        // global default.
                        let tokens = self.modelManager.generate(
                            prompt: prompt,
                            systemPrompt: systemPrompt ?? LLMModelManager.defaultSystemPrompt,
                            maxTokens: config.maxTokens,
                            stopSequences: config.stopSequences,
                            temperature: config.temperature,
                            topP: config.topP
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
    }

    func cancelGeneration() {
        // H4/H5: read-and-clear both task handles under the lock, then cancel
        // outside it.
        let (streamTask, futureTask) = lock.withLock { () -> (Task<Void, Never>?, Task<Void, Never>?) in
            let streamTask = generationTask
            let futureTask = futureGenerationTask
            generationTask = nil
            futureGenerationTask = nil
            return (streamTask, futureTask)
        }
        streamTask?.cancel()
        futureTask?.cancel()
        modelManager.cancelGeneration()
    }

    /// Cancels only the non-streaming (`Future`) generation task — invoked from
    /// the publisher's `receiveCancel` so a torn-down subscription stops the
    /// inference on the shared model (H5).
    private func cancelFutureGeneration() {
        let task = lock.withLock { () -> Task<Void, Never>? in
            let task = futureGenerationTask
            futureGenerationTask = nil
            return task
        }
        task?.cancel()
        modelManager.cancelGeneration()
    }
}
