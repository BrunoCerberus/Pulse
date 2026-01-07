import Foundation
#if canImport(UIKit)
    import UIKit
#endif
import llama

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// Uses llama.cpp for on-device inference with GGUF models.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    private let queue = DispatchQueue(label: "com.pulse.llm", qos: .userInitiated)
    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    // llama.cpp state
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var isCancelled = false

    private init() {
        setupMemoryWarningObserver()
        // Initialize llama backend
        llama_backend_init()
    }

    deinit {
        unloadModelSync()
        llama_backend_free()
    }

    // MARK: - Public API

    /// Check if model is currently loaded
    var modelIsLoaded: Bool {
        queue.sync { model != nil && context != nil }
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
                if self.model != nil {
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

                // Load model
                var modelParams = llama_model_default_params()
                modelParams.n_gpu_layers = 0 // CPU only for iOS compatibility

                guard let loadedModel = llama_load_model_from_file(modelPath, modelParams) else {
                    self.logger.error("Failed to load model from file", category: self.logCategory)
                    continuation.resume(throwing: LLMError.modelLoadFailed("Failed to load GGUF model"))
                    return
                }

                self.model = loadedModel
                progressHandler(0.7)

                // Create context
                var contextParams = llama_context_default_params()
                contextParams.n_ctx = UInt32(LLMConfiguration.contextSize)
                contextParams.n_batch = UInt32(LLMConfiguration.batchSize)
                contextParams.n_threads = UInt32(LLMConfiguration.threadCount)
                contextParams.n_threads_batch = UInt32(LLMConfiguration.threadCount)

                guard let ctx = llama_new_context_with_model(loadedModel, contextParams) else {
                    llama_free_model(loadedModel)
                    self.model = nil
                    self.logger.error("Failed to create context", category: self.logCategory)
                    continuation.resume(throwing: LLMError.modelLoadFailed("Failed to create inference context"))
                    return
                }

                self.context = ctx
                progressHandler(1.0)
                self.logger.info("Model loaded successfully", category: self.logCategory)
                continuation.resume()
            }
        }
    }

    /// Unload model and free memory
    func unloadModel() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                self?.unloadModelSync()
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

            queue.async { [weak self] in
                guard let self else {
                    continuation.finish(throwing: LLMError.serviceUnavailable)
                    return
                }

                guard let model = self.model, let ctx = self.context else {
                    continuation.finish(throwing: LLMError.modelNotLoaded)
                    return
                }

                self.isCancelled = false

                do {
                    try self.runInference(
                        model: model,
                        context: ctx,
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
        model: OpaquePointer,
        context ctx: OpaquePointer,
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        stopSequences: [String],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws {
        // Tokenize prompt
        let promptCString = prompt.cString(using: .utf8) ?? []
        let maxTokenCount = Int32(prompt.count + 128)
        var tokens = [llama_token](repeating: 0, count: Int(maxTokenCount))

        let tokenCount = llama_tokenize(
            model,
            promptCString,
            Int32(promptCString.count),
            &tokens,
            maxTokenCount,
            true, // add_special (BOS)
            false // parse_special
        )

        guard tokenCount > 0 else {
            throw LLMError.generationFailed("Failed to tokenize prompt")
        }

        tokens = Array(tokens.prefix(Int(tokenCount)))
        logger.info("Tokenized prompt: \(tokenCount) tokens", category: logCategory)

        // Clear KV cache
        llama_kv_cache_clear(ctx)

        // Create batch for prompt processing
        var batch = llama_batch_init(Int32(LLMConfiguration.batchSize), 0, 1)
        defer { llama_batch_free(batch) }

        // Add prompt tokens to batch
        for (index, token) in tokens.enumerated() {
            llama_batch_add_simple(&batch, token, Int32(index), index == tokens.count - 1)
        }

        // Process prompt
        if llama_decode(ctx, batch) != 0 {
            throw LLMError.generationFailed("Failed to process prompt")
        }

        // Create sampling context
        var sparams = llama_sampling_params()
        sparams.temp = temperature
        sparams.top_p = topP
        sparams.top_k = 40
        sparams.seed = UInt32.random(in: 0 ... UInt32.max)

        guard let samplingCtx = llama_sampling_init(sparams) else {
            throw LLMError.generationFailed("Failed to initialize sampler")
        }
        defer { llama_sampling_free(samplingCtx) }

        // Generate tokens
        var generatedText = ""
        var currentPos = Int32(tokens.count)
        let eosToken = llama_token_eos(model)

        for _ in 0 ..< maxTokens {
            if isCancelled {
                throw LLMError.generationCancelled
            }

            // Sample next token
            let newToken = llama_sampling_sample(samplingCtx, ctx, nil, -1)
            llama_sampling_accept(samplingCtx, ctx, newToken, true)

            // Check for EOS
            if newToken == eosToken {
                break
            }

            // Convert token to text
            let piece = tokenToString(model: model, token: newToken)

            // Check stop sequences
            generatedText += piece
            if stopSequences.contains(where: { generatedText.contains($0) }) {
                // Remove stop sequence from output
                for stop in stopSequences {
                    if let range = generatedText.range(of: stop) {
                        generatedText = String(generatedText[..<range.lowerBound])
                    }
                }
                continuation.yield(piece)
                break
            }

            continuation.yield(piece)

            // Prepare next batch
            llama_batch_clear(&batch)
            llama_batch_add_simple(&batch, newToken, currentPos, true)
            currentPos += 1

            // Decode
            if llama_decode(ctx, batch) != 0 {
                throw LLMError.generationFailed("Decode failed at position \(currentPos)")
            }
        }

        continuation.finish()
    }

    private func tokenToString(model: OpaquePointer, token: llama_token) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = llama_token_to_piece(model, token, &buffer, 256, false)
        if length > 0 {
            return String(cString: buffer)
        }
        return ""
    }

    // MARK: - Private Helpers

    private func unloadModelSync() {
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let model = model {
            llama_free_model(model)
            self.model = nil
        }
        logger.info("Model unloaded", category: logCategory)
    }

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

// MARK: - llama_batch helpers

private func llama_batch_add_simple(_ batch: inout llama_batch, _ token: llama_token, _ pos: Int32, _ logits: Bool) {
    batch.token[Int(batch.n_tokens)] = token
    batch.pos[Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = 1
    batch.seq_id[Int(batch.n_tokens)]![0] = 0
    batch.logits[Int(batch.n_tokens)] = logits ? 1 : 0
    batch.n_tokens += 1
}

private func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}
