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

    /// Generation gate (H3): `true` while a generation holds the single shared
    /// LlamaService context. The underlying `LlamaService.streamCompletion`
    /// silently cancels any in-flight generation on every new call, so without
    /// this gate a second feature (Summarization / Daily Digest / topic
    /// extraction) would abort the first. We choose **fail-fast**: a concurrent
    /// `generate` does NOT clobber the in-flight one — it finishes immediately
    /// with `LLMError.busy` (a transient signal every consumer already handles
    /// via `catch`/`receiveCompletion`; background topic extraction retries on
    /// it rather than dropping the event). Guarded
    /// by `lock`; always cleared in the inference `defer` so a finished or
    /// cancelled generation releases the gate.
    private var isGenerating = false

    /// Set while a memory-warning unload is tearing down the active generation
    /// (M13). Lets the inference loop surface an honest `LLMError.memoryPressure`
    /// (the same signal `TopicExtractionDrainer` keys off to retry later)
    /// instead of a generic `.generationCancelled`. Guarded by `lock`.
    private var unloadingForMemoryPressure = false

    /// Async-safe lock protecting `llamaService`, `generationTask`,
    /// `isGenerating`, and `unloadingForMemoryPressure`.
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
            let service = try await createAndWarmUpService(modelURL: modelURL, progressHandler: progressHandler)
            let boxedService = UncheckedSendableBox(value: service)
            let wasAlreadyLoaded = lock.withLock {
                if llamaService != nil {
                    return true
                }
                llamaService = boxedService.value
                return false
            }
            if wasAlreadyLoaded {
                // Another thread loaded first — discard our instance; LlamaService cleans up via deinit
                return
            }

            progressHandler(1.0)
            logger.info("Model loaded successfully", category: logCategory)
        } catch {
            logger.error("Failed to load model: \(error)", category: logCategory)
            throw LLMError.modelLoadFailed(error.localizedDescription)
        }
    }

    private func createAndWarmUpService(
        modelURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> LlamaService {
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

        // Warm up the service to trigger lazy model load
        let warmupMessages = [LlamaChatMessage(role: .system, content: "You are a helpful assistant.")]
        try await service.processMessages(warmupMessages)

        return service
    }

    /// Unload model and free memory.
    ///
    /// Awaits in-flight generation termination before releasing the service so
    /// the shared model isn't deallocated mid-inference (M13). Routes through
    /// the generation `Task`, which calls `LlamaService.stopCompletion()`
    /// (`cancelAndWait`) on cancellation, so this is bounded and deadlock-free:
    /// we await OUTSIDE the lock and the inference path takes the lock only for
    /// brief read-and-clear/assign sections.
    func unloadModel() async {
        await cancelGenerationAndWait()
        lock.withLock {
            llamaService = nil
        }
        logger.info("Model unloaded", category: logCategory)
    }

    /// Unload triggered by a memory warning (M13).
    ///
    /// Flags the active generation so it terminates with an honest
    /// `LLMError.memoryPressure` — the transient signal `TopicExtractionDrainer`
    /// retries on — rather than a generic `.generationCancelled`, then awaits
    /// termination before releasing the service.
    func unloadModelForMemoryPressure() async {
        lock.withLock { unloadingForMemoryPressure = true }
        await unloadModel()
    }

    /// Cancel current generation (fire-and-forget).
    ///
    /// Reads-and-clears `generationTask` under the lock, then cancels OUTSIDE
    /// the lock (H4).
    func cancelGeneration() {
        let task = lock.withLock { () -> Task<Void, Never>? in
            let task = generationTask
            generationTask = nil
            return task
        }
        task?.cancel()
    }

    /// Cancel current generation and await its termination.
    ///
    /// Same lock-safe read-and-clear as `cancelGeneration()`, but also awaits
    /// the task's completion (outside the lock) so callers like `unloadModel`
    /// can guarantee the shared context is idle before mutating it.
    private func cancelGenerationAndWait() async {
        let task = lock.withLock { () -> Task<Void, Never>? in
            let task = generationTask
            generationTask = nil
            return task
        }
        task?.cancel()
        await task?.value
    }

    /// Generate text from prompt.
    ///
    /// `temperature`/`topP` are the per-call sampling parameters (L9); they
    /// default to the global `LLMConfiguration` values so existing callers keep
    /// the previous behavior.
    func generate(
        prompt: String,
        systemPrompt: String = LLMModelManager.defaultSystemPrompt,
        maxTokens: Int,
        stopSequences: [String],
        temperature: Float = LLMConfiguration.temperature,
        topP: Float = 0.95
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            // H3: fail-fast generation gate. Claim the shared context under the
            // lock; if another feature is already generating, bail through the
            // existing error channel instead of clobbering it.
            let didAcquire = self.lock.withLock { () -> Bool in
                if self.isGenerating { return false }
                self.isGenerating = true
                return true
            }
            guard didAcquire else {
                self.logger.warning(
                    "Generation already in progress — rejecting concurrent request",
                    category: self.logCategory
                )
                continuation.finish(throwing: LLMError.busy)
                return
            }

            // H4: assign the task under the lock.
            self.lock.withLock {
                self.generationTask = Task {
                    await self.runInference(
                        prompt: prompt,
                        systemPrompt: systemPrompt,
                        maxTokens: maxTokens,
                        stopSequences: stopSequences,
                        temperature: temperature,
                        topP: topP,
                        continuation: continuation
                    )
                }
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
                    await self.unloadModelForMemoryPressure()
                }
            }
        #endif
    }
}

// MARK: - Private Inference

private extension LLMModelManager {
    // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
    func runInference(
        prompt: String,
        systemPrompt: String,
        maxTokens: Int,
        stopSequences: [String],
        temperature: Float,
        topP: Float,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        // H3: release the generation gate when this inference finishes for ANY
        // reason (success, throw, cancellation, memory-pressure teardown), and
        // reset the memory-pressure teardown flag so it can't leak to the next
        // generation.
        defer {
            lock.withLock {
                isGenerating = false
                unloadingForMemoryPressure = false
            }
        }

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

            // L9: thread the per-call temperature/topP through to the sampler;
            // `LLMConfiguration.temperature` is only the default fallback (set
            // at the call site). The shared LlamaService stream is bounded by
            // `maxTokenCount` (context size), so `maxTokens` stays a char-based
            // safety cutoff below rather than a sampler argument.
            let samplingConfig = LlamaSamplingConfig(
                temperature: temperature,
                seed: UInt32.random(in: 0 ..< UInt32.max),
                topP: topP
            )

            let boxedService = UncheckedSendableBox(value: service)
            let responseStream = try await boxedService.value.streamCompletion(
                of: messages,
                samplingConfig: samplingConfig
            )

            // L10: stop-sequence detection across chunk boundaries. Markers can
            // split across streamed chunks (e.g. "</summ" + "ary>"), so we keep
            // a rolling `pending` buffer and only emit text we're sure isn't the
            // start of a stop marker. We retain at most `maxStopLen - 1`
            // trailing chars (the longest a partial marker can be) — memory is
            // bounded by the longest stop sequence plus the current chunk.
            let maxStopLen = stopSequences.map(\.count).max() ?? 0
            let retainCount = max(maxStopLen - 1, 0)

            var emittedCharacters = 0
            var pending = ""
            var stopDetected = false

            for try await text in responseStream {
                if Task.isCancelled {
                    await boxedService.value.stopCompletion()
                    finishCancelled(continuation)
                    return
                }

                pending += text

                // Stop-marker check on the rolling boundary: if any marker now
                // appears in `pending`, emit only the prefix before the
                // earliest marker and stop.
                if let stopRange = earliestStopRange(in: pending, stopSequences: stopSequences) {
                    let prefix = String(pending[..<stopRange.lowerBound])
                    if !prefix.isEmpty {
                        continuation.yield(prefix)
                        emittedCharacters += prefix.count
                    }
                    stopDetected = true
                    break
                }

                // No complete marker: safe to emit everything except the tail
                // that might begin a marker completing in a later chunk.
                if pending.count > retainCount {
                    let splitIndex = pending.index(pending.endIndex, offsetBy: -retainCount)
                    let emittable = String(pending[..<splitIndex])
                    pending = String(pending[splitIndex...])
                    if !emittable.isEmpty {
                        continuation.yield(emittable)
                        emittedCharacters += emittable.count
                    }
                }

                if emittedCharacters > maxTokens * 4 {
                    break
                }
            }

            // Flush any retained tail when generation ended naturally without a
            // stop marker (the tail was held back only against a possible split).
            if !stopDetected, !pending.isEmpty {
                continuation.yield(pending)
                emittedCharacters += pending.count
            }

            if !Task.isCancelled {
                await boxedService.value.stopCompletion()
            }

            continuation.finish()
            logger.info("Inference completed, generated \(emittedCharacters) characters", category: logCategory)

        } catch {
            if Task.isCancelled {
                finishCancelled(continuation)
            } else {
                logger.error("Inference failed: \(error)", category: logCategory)
                continuation.finish(throwing: LLMError.generationFailed(error.localizedDescription))
            }
        }
    }

    /// Finishes a cancelled stream with the honest error for the cause (M13):
    /// `.memoryPressure` when a memory-warning teardown triggered the cancel
    /// (the transient signal `TopicExtractionDrainer` retries on), otherwise the
    /// usual `.generationCancelled`.
    func finishCancelled(_ continuation: AsyncThrowingStream<String, Error>.Continuation) {
        let memoryPressure = lock.withLock { unloadingForMemoryPressure }
        if memoryPressure {
            logger.warning("Generation aborted by memory pressure", category: logCategory)
            continuation.finish(throwing: LLMError.memoryPressure)
        } else {
            logger.info("Generation cancelled", category: logCategory)
            continuation.finish(throwing: LLMError.generationCancelled)
        }
    }

    /// Returns the range of the earliest-starting stop sequence found in `text`,
    /// or `nil` if none is present. Ties broken by earliest start index so we
    /// always truncate at the first marker boundary.
    func earliestStopRange(in text: String, stopSequences: [String]) -> Range<String.Index>? {
        var earliest: Range<String.Index>?
        for stop in stopSequences where !stop.isEmpty {
            if let range = text.range(of: stop) {
                if earliest == nil || range.lowerBound < earliest!.lowerBound {
                    earliest = range
                }
            }
        }
        return earliest
    }
}
