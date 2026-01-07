import Foundation
#if canImport(UIKit)
    import UIKit
#endif
import LocalLlama

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses SwiftLlama actor for thread-safe on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    /// SwiftLlama actor instance - all operations are thread-safe
    private var swiftLlama: SwiftLlama?
    private var isCancelled = false

    /// Lock for protecting swiftLlama reference changes only
    private let lock = NSLock()

    private init() {
        setupMemoryWarningObserver()
    }

    // MARK: - Public API

    /// Check if model is currently loaded
    var modelIsLoaded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return swiftLlama != nil
    }

    /// Load the GGUF model into memory
    func loadModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        // Quick check if already loaded (minimal lock time)
        lock.lock()
        if swiftLlama != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        // Perform validations outside the lock to reduce contention
        guard hasAdequateMemory() else {
            logger.warning("Insufficient memory to load model", category: logCategory)
            throw LLMError.memoryPressure
        }

        progressHandler(0.1)

        guard let modelPath = LLMConfiguration.modelURL?.path,
              FileManager.default.fileExists(atPath: modelPath)
        else {
            logger.warning("Model file not found at expected path", category: logCategory)
            throw LLMError.modelLoadFailed(
                "Model file not bundled. Please add the GGUF model to Resources/Models/"
            )
        }

        logger.info("Loading model from: \(modelPath)", category: logCategory)
        progressHandler(0.3)

        // Create and initialize outside the lock (expensive operation)
        let llama = SwiftLlama(modelPath: modelPath)

        do {
            progressHandler(0.5)
            try await llama.initialize()
            progressHandler(0.8)

            // Only lock when setting the shared state
            lock.lock()
            // Double-check: another caller may have loaded while we were initializing
            if swiftLlama != nil {
                lock.unlock()
                // Another thread loaded first, discard our instance
                return
            }
            swiftLlama = llama
            lock.unlock()

            progressHandler(1.0)
            logger.info("Model loaded successfully", category: logCategory)
        } catch {
            logger.error("Failed to load model: \(error)", category: logCategory)
            throw LLMError.modelLoadFailed(error.localizedDescription)
        }
    }

    /// Unload model and free memory
    func unloadModel() async {
        lock.lock()
        swiftLlama = nil
        lock.unlock()
        logger.info("Model unloaded", category: logCategory)
    }

    /// Cancel current generation
    func cancelGeneration() {
        isCancelled = true
    }

    /// Generate text from prompt
    /// - Parameters:
    ///   - prompt: The user prompt/message to generate from
    ///   - systemPrompt: System prompt defining assistant behavior
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Sampling temperature (unused - LocalLlama Configuration.temperature is used instead)
    ///   - topP: Top-p sampling (unused - LocalLlama Configuration.topP is used instead)
    ///   - stopSequences: Sequences that stop generation when encountered
    /// - Note: temperature and topP are kept for API compatibility. To customize these values,
    ///   configure them when creating the SwiftLlama instance via Configuration.
    func generate(
        prompt: String,
        systemPrompt: String = DigestPromptBuilder.systemPrompt,
        maxTokens: Int,
        temperature _: Float,
        topP _: Float,
        stopSequences: [String]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            Task {
                await self.runInference(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    maxTokens: maxTokens,
                    stopSequences: stopSequences,
                    continuation: continuation
                )
            }
        }
    }

    // MARK: - Private Inference

    private func runInference(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int,
        stopSequences: [String],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        lock.lock()
        guard let llama = swiftLlama else {
            lock.unlock()
            continuation.finish(throwing: LLMError.modelNotLoaded)
            return
        }
        lock.unlock()

        isCancelled = false

        // Create Prompt for Llama 3.2 model
        let llamaPrompt = Prompt(
            type: .llama3,
            systemPrompt: systemPrompt,
            userMessage: prompt
        )

        logger.info("Starting inference...", category: logCategory)

        do {
            // Generate on the SwiftLlama actor - fully thread-safe
            let result = try await llama.generate(for: llamaPrompt)

            // Check cancellation before processing results to avoid yielding cancelled output
            if isCancelled {
                logger.info("Generation cancelled by user", category: logCategory)
                continuation.finish(throwing: LLMError.generationCancelled)
                return
            }

            // Process result - apply stop sequences and max length
            var processedResult = result
            for stop in stopSequences {
                if let range = processedResult.range(of: stop) {
                    processedResult = String(processedResult[..<range.lowerBound])
                    break
                }
            }

            // Trim to approximate max tokens (multiply by 4 as rough chars-per-token estimate)
            let maxCharacters = maxTokens * 4
            if processedResult.count > maxCharacters {
                processedResult = String(processedResult.prefix(maxCharacters))
            }

            // Final cancellation check before yielding
            if isCancelled {
                logger.info("Generation cancelled before yielding result", category: logCategory)
                continuation.finish(throwing: LLMError.generationCancelled)
                return
            }

            // Yield the entire result at once
            continuation.yield(processedResult)
            continuation.finish()

            logger.info("Inference completed, generated \(processedResult.count) characters", category: logCategory)
        } catch {
            logger.error("Inference failed: \(error)", category: logCategory)
            continuation.finish(throwing: error)
        }
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
