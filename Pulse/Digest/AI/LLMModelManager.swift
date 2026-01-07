import Foundation
#if canImport(UIKit)
    import UIKit
#endif
import SwiftLlama

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses SwiftLlama for on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    private let queue = DispatchQueue(label: "com.pulse.llm", qos: .userInitiated)
    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    // SwiftLlama instance
    private var swiftLlama: SwiftLlama?
    private var isCancelled = false

    private init() {
        setupMemoryWarningObserver()
    }

    deinit {
        swiftLlama = nil
    }

    // MARK: - Public API

    /// Check if model is currently loaded
    var modelIsLoaded: Bool {
        queue.sync { swiftLlama != nil }
    }

    /// Load the GGUF model into memory
    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: LLMError.serviceUnavailable)
                    return
                }

                // Already loaded
                if self.swiftLlama != nil {
                    continuation.resume()
                    return
                }

                // Check available memory
                guard self.hasAdequateMemory() else {
                    self.logger.warning("Insufficient memory to load model", category: self.logCategory)
                    continuation.resume(throwing: LLMError.memoryPressure)
                    return
                }

                progressHandler(0.1)

                // Verify model file exists
                guard let modelPath = LLMConfiguration.modelURL?.path,
                      FileManager.default.fileExists(atPath: modelPath)
                else {
                    self.logger.warning("Model file not found", category: self.logCategory)
                    continuation.resume(throwing: LLMError.modelLoadFailed(
                        "Model file not bundled. Please add the GGUF model to Resources/Models/"
                    ))
                    return
                }

                progressHandler(0.3)

                // Load model using SwiftLlama
                do {
                    let llama = try SwiftLlama(modelPath: modelPath)
                    progressHandler(0.7)

                    self.swiftLlama = llama
                    progressHandler(1.0)
                    self.logger.info("Model loaded successfully", category: self.logCategory)
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to load model: \(error)", category: self.logCategory)
                    continuation.resume(throwing: LLMError.modelLoadFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Unload model and free memory
    func unloadModel() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                self?.swiftLlama = nil
                self?.logger.info("Model unloaded", category: self?.logCategory ?? "")
                continuation.resume()
            }
        }
    }

    /// Cancel current generation
    func cancelGeneration() {
        queue.async { [weak self] in
            self?.isCancelled = true
        }
    }

    /// Generate tokens from prompt
    func generate(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        stopSequences: [String]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            Task {
                do {
                    try await self.runInference(
                        prompt: prompt,
                        maxTokens: maxTokens,
                        temperature: temperature,
                        topP: topP,
                        stopSequences: stopSequences,
                        continuation: continuation
                    )
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Inference

    private func runInference(
        prompt: String,
        maxTokens: Int,
        temperature _: Float,
        topP _: Float,
        stopSequences: [String],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let llama = queue.sync(execute: { swiftLlama }) else {
            throw LLMError.modelNotLoaded
        }

        // Reset cancellation flag
        queue.sync { isCancelled = false }

        var generatedText = ""

        // Create Prompt for Llama 3.2 model
        let llamaPrompt = Prompt(
            type: .llama3,
            systemPrompt: "You are a helpful news digest assistant.",
            userMessage: prompt
        )

        // Use SwiftLlama's AsyncStream for token generation
        // Explicitly type to get the AsyncThrowingStream overload
        let stream: AsyncThrowingStream<String, Error> = await llama.start(for: llamaPrompt)

        for try await token in stream {
            // Check cancellation
            if queue.sync(execute: { isCancelled }) {
                throw LLMError.generationCancelled
            }

            generatedText += token

            // Check stop sequences
            var shouldStop = false
            for stop in stopSequences {
                if generatedText.contains(stop) {
                    shouldStop = true
                    break
                }
            }

            if shouldStop {
                break
            }

            // Check max tokens (approximate by character count)
            if generatedText.count > maxTokens * 4 {
                break
            }

            continuation.yield(token)
        }

        continuation.finish()
    }

    // MARK: - Private Helpers

    private func hasAdequateMemory() -> Bool {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return true }

        let usedMemory = info.resident_size
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = totalMemory - usedMemory

        return availableMemory > LLMConfiguration.minimumAvailableMemory
    }

    private func setupMemoryWarningObserver() {
        #if canImport(UIKit)
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.logger.warning("Memory warning received - unloading model", category: self.logCategory)
                Task {
                    await self.unloadModel()
                }
            }
        #endif
    }
}
