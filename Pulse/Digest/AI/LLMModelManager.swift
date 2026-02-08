import EntropyCore
import Foundation
import LeapSDK
import os
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - LLM Model Manager

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses LEAP SDK's ModelRunner for on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    /// Default system prompt for general-purpose LLM interactions
    static let defaultSystemPrompt = "You are a helpful assistant that provides clear, concise responses."

    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    /// LEAP ModelRunner instance
    private var modelRunner: ModelRunner?
    private var generationTask: Task<Void, Never>?
    private var memoryWarningObserverToken: NSObjectProtocol?

    /// Async-safe lock for protecting modelRunner reference changes
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
        lock.withLock { modelRunner != nil }
    }

    /// Load the GGUF model into memory
    func loadModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        let alreadyLoaded = lock.withLock { modelRunner != nil }
        if alreadyLoaded { return }

        let memoryTier = MemoryTier.current
        logMemoryTier(memoryTier)

        guard hasAdequateMemory(for: .modelLoad) else {
            logger.warning("Insufficient memory (tier: \(memoryTier.rawValue))", category: logCategory)
            throw LLMError.memoryPressure
        }

        progressHandler(0.1)

        guard let modelURL = LLMConfiguration.modelURL,
              FileManager.default.fileExists(atPath: modelURL.path)
        else {
            logger.warning("Model file not found", category: logCategory)
            throw LLMError.modelLoadFailed("Model file not bundled. Please add the GGUF model to Resources/Models/")
        }

        logger.info("Loading model from: \(modelURL.path)", category: logCategory)
        progressHandler(0.3)

        do {
            progressHandler(0.5)
            let runner = try await Leap.load(url: modelURL)
            progressHandler(0.8)

            // Only lock when setting the shared state
            // Double-check: another caller may have loaded while we were initializing
            let wasAlreadyLoaded = lock.withLock {
                if modelRunner != nil {
                    return true
                }
                modelRunner = runner
                return false
            }
            if wasAlreadyLoaded {
                // Another thread loaded first, discard our instance
                await runner.unload()
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
        let runner = lock.withLock { () -> ModelRunner? in
            let current = modelRunner
            modelRunner = nil
            return current
        }
        await runner?.unload()
        logger.info("Model unloaded", category: logCategory)
    }

    /// Cancel current generation
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }

    /// Generate text from prompt
    /// - Parameters:
    ///   - prompt: The user prompt/message to generate from
    ///   - systemPrompt: System prompt defining assistant behavior
    ///   - maxTokens: Maximum tokens to generate
    ///   - stopSequences: Sequences that stop generation when encountered
    func generate(
        prompt: String,
        systemPrompt: String = LLMModelManager.defaultSystemPrompt,
        maxTokens: Int,
        stopSequences: [String]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            self.generationTask = Task {
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
        guard let runner = lock.withLock({ modelRunner }) else {
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
            // Create conversation with system prompt using LEAP SDK
            let conversation = runner.createConversation(systemPrompt: systemPrompt)

            // Send user message and stream response
            let userMessage = ChatMessage(role: .user, content: [.text(prompt)])
            let responseStream = conversation.generateResponse(message: userMessage)

            var totalCharacters = 0
            var stopDetected = false

            for try await response in responseStream {
                if Task.isCancelled {
                    logger.info("Generation cancelled by user", category: logCategory)
                    continuation.finish(throwing: LLMError.generationCancelled)
                    return
                }

                switch response {
                case let .chunk(text):
                    // Check for stop sequences in the accumulated text
                    for stop in stopSequences {
                        if text.contains(stop) {
                            // Yield text up to the stop sequence
                            if let range = text.range(of: stop) {
                                let prefix = String(text[..<range.lowerBound])
                                if !prefix.isEmpty {
                                    continuation.yield(prefix)
                                }
                            }
                            stopDetected = true
                            break
                        }
                    }

                    if stopDetected { break }

                    // Check max tokens (approximate by characters / 4)
                    totalCharacters += text.count
                    if totalCharacters > maxTokens * 4 {
                        break
                    }

                    continuation.yield(text)

                case .complete:
                    break

                default:
                    break
                }

                if stopDetected || totalCharacters > maxTokens * 4 {
                    break
                }
            }

            continuation.finish()
            logger.info("Inference completed, generated \(totalCharacters) characters", category: logCategory)

        } catch let error as LeapError {
            logger.error("LEAP inference failed: \(error)", category: logCategory)

            switch error {
            case .promptExceedContextLengthFailure:
                continuation.finish(throwing: LLMError.generationFailed("Prompt exceeds context window"))
            default:
                continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
            }
        } catch {
            if Task.isCancelled {
                logger.info("Generation cancelled", category: logCategory)
                continuation.finish(throwing: LLMError.generationCancelled)
            } else {
                logger.error("Inference failed with unexpected error: \(error)", category: logCategory)
                continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Private Helpers

    private func logMemoryTier(_ tier: MemoryTier) {
        let ctx = LLMConfiguration.contextSize
        logger.info("Memory tier: \(tier.description), ctx: \(ctx)", category: logCategory)
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
