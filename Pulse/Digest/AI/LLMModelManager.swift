import Foundation
import LocalLlama
import os
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - LLM Model Manager

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses SwiftLlama actor for thread-safe on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable { // swiftlint:disable:this type_body_length
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

    // MARK: - Simulator Warning State

    /// Reference type wrapper for simulator warning state.
    /// Required because OSAllocatedUnfairLock needs a reference type to properly
    /// synchronize mutable state across threads.
    private final class SimulatorWarningState: @unchecked Sendable {
        var hasLogged = false
    }

    /// Thread-safe static lock for one-time simulator warning log.
    /// Using a lock ensures the warning is logged exactly once even under concurrent access.
    private static let simulatorWarningLock = OSAllocatedUnfairLock(initialState: SimulatorWarningState())

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
        let alreadyLoaded = lock.withLock { swiftLlama != nil }
        if alreadyLoaded { return }

        let memoryTier = MemoryTier.current
        logMemoryTier(memoryTier)

        guard hasAdequateMemory(for: .modelLoad) else {
            logger.warning("Insufficient memory (tier: \(memoryTier.rawValue))", category: logCategory)
            throw LLMError.memoryPressure
        }

        progressHandler(0.1)

        guard let modelPath = LLMConfiguration.modelURL?.path,
              FileManager.default.fileExists(atPath: modelPath)
        else {
            logger.warning("Model file not found", category: logCategory)
            throw LLMError.modelLoadFailed("Model file not bundled. Please add the GGUF model to Resources/Models/")
        }

        logger.info("Loading model from: \(modelPath)", category: logCategory)
        progressHandler(0.3)

        let llama = SwiftLlama(modelPath: modelPath, modelConfiguration: makeConfiguration())

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
        guard hasAdequateMemory(for: .inference) else {
            let tier = MemoryTier.current.rawValue
            logger.warning("Insufficient memory for inference (tier: \(tier))", category: logCategory)
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

    private func logMemoryTier(_ tier: MemoryTier) {
        let ctx = LLMConfiguration.contextSize
        let batch = LLMConfiguration.batchSize
        logger.info("Memory tier: \(tier.description), ctx: \(ctx), batch: \(batch)", category: logCategory)
    }

    private func makeConfiguration() -> Configuration {
        Configuration(
            topK: 40,
            topP: 0.9,
            nCTX: LLMConfiguration.contextSize,
            temperature: 0.5,
            batchSize: LLMConfiguration.batchSize,
            maxTokenCount: LLMConfiguration.contextSize,
            stopTokens: ["</digest>", "---"],
            timeout: LLMConfiguration.generationTimeout
        )
    }

    /// Checks if the device has adequate memory for the specified operation.
    private func hasAdequateMemory(for operation: MemoryOperation) -> Bool {
        // Check system memory pressure first (available on iOS 13+)
        if isUnderMemoryPressure() {
            logger.warning("System is under memory pressure", category: logCategory)
            return false
        }

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

        let hasEnough = availableMemory > operation.minimumMemory

        if !hasEnough {
            let availableMB = availableMemory / (1024 * 1024)
            let requiredMB = operation.minimumMemory / (1024 * 1024)
            logger.warning(
                "Memory check failed: \(availableMB)MB available, \(requiredMB)MB required for \(operation)",
                category: logCategory
            )
        }

        return hasEnough
    }

    /// Checks if the system is under memory pressure using `os_proc_available_memory`.
    /// Memory pressure detection is disabled in simulator - test on physical devices.
    private func isUnderMemoryPressure() -> Bool {
        #if targetEnvironment(simulator)
            #if DEBUG
                if ProcessInfo.processInfo.environment["FORCE_MEMORY_PRESSURE_CHECK"] == "1" {
                    return checkActualMemoryPressure()
                }
                Self.simulatorWarningLock.withLock { state in
                    if !state.hasLogged {
                        state.hasLogged = true
                        logger.debug("Memory check disabled in sim", category: logCategory)
                    }
                }
            #endif
            return false
        #else
            return checkActualMemoryPressure()
        #endif
    }

    /// Performs the actual memory pressure check using os_proc_available_memory.
    /// Extracted to allow testing via FORCE_MEMORY_PRESSURE_CHECK environment variable.
    private func checkActualMemoryPressure() -> Bool {
        // Use os_proc_available_memory (iOS 13+)
        // This is more accurate than calculating from task_info
        let availableMemory = os_proc_available_memory()
        // Consider system under pressure if less than 200MB available at OS level
        // This is a conservative threshold that catches critical states before OOM killer acts
        let criticalThreshold = 200 * 1024 * 1024 // 200MB
        return availableMemory < criticalThreshold
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
