import EntropyCore
import Foundation
import os
import SwiftLlama
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - LLM Model Manager

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses SwiftLlama (llama.cpp) for on-device inference with GGUF models.
/// This class is thread-safe using OSAllocatedUnfairLock for service access.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    /// Default system prompt for general-purpose LLM interactions
    static let defaultSystemPrompt = "You are a helpful assistant that provides clear, concise responses."

    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    /// SwiftLlama service instance
    private var llamaService: LlamaService?
    private var generationTask: Task<Void, Never>?
    private var memoryWarningObserverToken: NSObjectProtocol?

    /// Async-safe lock for protecting llamaService reference changes
    private let lock = OSAllocatedUnfairLock()

    // MARK: - Simulator Warning State

    /// Reference type wrapper for simulator warning state.
    private final class SimulatorWarningState: @unchecked Sendable {
        var hasLogged = false
    }

    private static let simulatorWarningLock = OSAllocatedUnfairLock(initialState: SimulatorWarningState())

    private init() {
        setupMemoryWarningObserver()
    }

    deinit {
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
        lock.withLock { llamaService != nil }
    }

    /// Load the GGUF model into memory
    func loadModel(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        let alreadyLoaded = lock.withLock { llamaService != nil }
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

            let useGPU: Bool
            #if targetEnvironment(simulator)
                useGPU = false
            #else
                useGPU = true
            #endif

            let config = LlamaConfig(
                batchSize: 512,
                maxTokenCount: UInt32(LLMConfiguration.contextSize),
                useGPU: useGPU
            )

            let service = LlamaService(modelUrl: modelURL, config: config)
            progressHandler(0.8)

            // Warm up the service by processing an empty message to trigger lazy model load
            let warmupMessages = [LlamaChatMessage(role: .system, content: "You are a helpful assistant.")]
            try await service.processMessages(warmupMessages)

            let boxedService = UncheckedSendableBox(value: service)
            let wasAlreadyLoaded = lock.withLock {
                if llamaService != nil {
                    return true
                }
                llamaService = boxedService.value
                return false
            }
            if wasAlreadyLoaded {
                // Another thread loaded first — discard our instance
                // LlamaService cleans up via deinit when it goes out of scope
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
        cancelGeneration()
        lock.withLock {
            llamaService = nil
        }
        logger.info("Model unloaded", category: logCategory)
    }

    /// Cancel current generation
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }

    /// Generate text from prompt
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

    // MARK: - Private Helpers

    private func logMemoryTier(_ tier: MemoryTier) {
        let ctx = LLMConfiguration.contextSize
        logger.info("Memory tier: \(tier.description), ctx: \(ctx)", category: logCategory)
    }

    /// Checks if the device has adequate memory for the specified operation.
    private func hasAdequateMemory(for operation: MemoryOperation) -> Bool {
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

    private func checkActualMemoryPressure() -> Bool {
        let availableMemory = os_proc_available_memory()
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

// MARK: - Private Inference

private extension LLMModelManager {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func runInference(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int,
        stopSequences: [String],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        let boxedService: UncheckedSendableBox<LlamaService?> = lock.withLock {
            UncheckedSendableBox(value: llamaService)
        }
        guard let service = boxedService.value else {
            continuation.finish(throwing: LLMError.modelNotLoaded)
            return
        }

        guard hasAdequateMemory(for: .inference) else {
            let tier = MemoryTier.current.rawValue
            logger.warning("Insufficient memory for inference (tier: \(tier))", category: logCategory)
            continuation.finish(throwing: LLMError.memoryPressure)
            return
        }

        let estimatedPromptTokens = (systemPrompt.count + prompt.count) / 4
        logger.info(
            "Starting inference... (estimated prompt tokens: \(estimatedPromptTokens))",
            category: logCategory
        )

        if estimatedPromptTokens > LLMConfiguration.contextSize - LLMConfiguration.reservedContextTokens {
            logger.warning(
                // swiftlint:disable:next line_length
                "Prompt may exceed safe context size (\(estimatedPromptTokens) estimated vs \(LLMConfiguration.contextSize) max)",
                category: logCategory
            )
        }

        do {
            let messages = [
                LlamaChatMessage(role: .system, content: systemPrompt),
                LlamaChatMessage(role: .user, content: prompt),
            ]

            let samplingConfig = LlamaSamplingConfig(
                temperature: LLMConfiguration.temperature,
                seed: UInt32.random(in: 0 ..< UInt32.max)
            )

            let boxedService = UncheckedSendableBox(value: service)
            let responseStream = try await boxedService.value.streamCompletion(
                of: messages,
                samplingConfig: samplingConfig
            )

            var totalCharacters = 0
            var stopDetected = false

            for try await text in responseStream {
                if Task.isCancelled {
                    logger.info("Generation cancelled by user", category: logCategory)
                    await boxedService.value.stopCompletion()
                    continuation.finish(throwing: LLMError.generationCancelled)
                    return
                }

                // Check for stop sequences
                for stop in stopSequences where text.contains(stop) {
                    if let range = text.range(of: stop) {
                        let prefix = String(text[..<range.lowerBound])
                        if !prefix.isEmpty {
                            continuation.yield(prefix)
                        }
                    }
                    stopDetected = true
                    break
                }

                if stopDetected { break }

                totalCharacters += text.count
                if totalCharacters > maxTokens * 4 {
                    break
                }

                continuation.yield(text)
            }

            if !Task.isCancelled {
                await boxedService.value.stopCompletion()
            }

            continuation.finish()
            logger.info("Inference completed, generated \(totalCharacters) characters", category: logCategory)

        } catch {
            if Task.isCancelled {
                logger.info("Generation cancelled", category: logCategory)
                continuation.finish(throwing: LLMError.generationCancelled)
            } else {
                logger.error("Inference failed: \(error)", category: logCategory)
                continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
            }
        }
    }
}
