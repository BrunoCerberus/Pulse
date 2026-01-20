import Foundation
import os
#if canImport(UIKit)
    import UIKit
#endif
import LocalLlama

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses SwiftLlama actor for thread-safe on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    /// Default system prompt for general-purpose LLM interactions
    static let defaultSystemPrompt = "You are a helpful assistant that provides clear, concise responses."

    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    /// SwiftLlama actor instance - all operations are thread-safe
    private var swiftLlama: SwiftLlama?
    private var isCancelled = false
    private var memoryWarningObserverToken: NSObjectProtocol?

    /// Async-safe lock for protecting swiftLlama reference changes
    private let lock = OSAllocatedUnfairLock()

    private init() {
        setupMemoryWarningObserver()
    }

    deinit {
        // Note: As a singleton, this deinit is only called at app termination.
        // The memory warning observer is properly cleaned up to avoid dangling references.
        #if canImport(UIKit)
            if let token = memoryWarningObserverToken {
                NotificationCenter.default.removeObserver(token)
                memoryWarningObserverToken = nil
            }
        #endif
    }

    // MARK: - Public API

    /// Check if model is currently loaded
    var modelIsLoaded: Bool {
        lock.withLock { swiftLlama != nil }
    }

    /// Load the GGUF model into memory
    func loadModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        // Quick check if already loaded (minimal lock time)
        let alreadyLoaded = lock.withLock { swiftLlama != nil }
        if alreadyLoaded { return }

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

        // Create configuration with adequate context size for prompt + generation
        // The prompt can be ~2000 tokens, plus we want to generate ~500-1000 tokens
        // Batch size 2048 improves throughput on devices with adequate memory (4GB+)
        let config = Configuration(
            topK: 40,
            topP: 0.9,
            nCTX: 3072, // Reduced context window (prompt ~2000 + output ~1000)
            temperature: 0.5, // Lower temperature for more deterministic, focused output
            batchSize: 2048, // Larger batches improve inference throughput
            maxTokenCount: 3072, // Must be >= prompt tokens + max generated tokens
            stopTokens: ["</digest>", "---"],
            timeout: 120.0 // 2 minutes for full digest generation on mobile
        )

        // Create and initialize outside the lock (expensive operation)
        let llama = SwiftLlama(modelPath: modelPath, modelConfiguration: config)

        do {
            progressHandler(0.5)
            try llama.initialize()
            progressHandler(0.8)

            // Only lock when setting the shared state
            // Double-check: another caller may have loaded while we were initializing
            let wasAlreadyLoaded = lock.withLock {
                if swiftLlama != nil {
                    return true
                }
                swiftLlama = llama
                return false
            }
            if wasAlreadyLoaded {
                // Another thread loaded first, discard our instance
                return
            }

            progressHandler(1.0)
            logger.info("Model loaded successfully", category: logCategory)
        } catch {
            logger.error("Failed to load model: \(error)", category: logCategory)
            throw LLMError.modelLoadFailed(error.localizedDescription)
        }
    }

    /// Unload model and free memory
    func unloadModel() async {
        lock.withLock { swiftLlama = nil }
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
        systemPrompt: String = LLMModelManager.defaultSystemPrompt,
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func runInference(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int,
        stopSequences: [String],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        guard let llama = lock.withLock({ swiftLlama }) else {
            continuation.finish(throwing: LLMError.modelNotLoaded)
            return
        }

        // Pre-inference memory check to prevent crashes during generation
        guard hasAdequateMemory() else {
            logger.warning("Insufficient memory for inference", category: logCategory)
            continuation.finish(throwing: LLMError.memoryPressure)
            return
        }

        isCancelled = false

        // Create Prompt for Llama 3.2 model
        let llamaPrompt = Prompt(
            type: .llama3,
            systemPrompt: systemPrompt,
            userMessage: prompt
        )

        // Log prompt size for debugging context overflow issues
        let estimatedPromptTokens = (systemPrompt.count + prompt.count) / 4
        logger.info(
            "Starting inference... (estimated prompt tokens: \(estimatedPromptTokens))",
            category: logCategory
        )

        // Warn if prompt might be too large for context window
        if estimatedPromptTokens > LLMConfiguration.contextSize - LLMConfiguration.reservedContextTokens {
            logger.warning(
                // swiftlint:disable:next line_length
                "Prompt may exceed safe context size (\(estimatedPromptTokens) estimated vs \(LLMConfiguration.contextSize) max)",
                category: logCategory
            )
        }

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
        } catch let error as NSError {
            // Handle specific error cases that could indicate crashes
            logger.error("Inference failed: \(error)", category: logCategory)

            if error.domain == "LocalLlama" || error.domain == NSPOSIXErrorDomain {
                // Native library errors - may indicate memory or context issues
                if error.code == ENOMEM || error.localizedDescription.lowercased().contains("memory") {
                    continuation.finish(throwing: LLMError.memoryPressure)
                    return
                }
            }

            continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
        } catch {
            logger.error("Inference failed with unexpected error: \(error)", category: logCategory)
            continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
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
            memoryWarningObserverToken = NotificationCenter.default.addObserver(
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
