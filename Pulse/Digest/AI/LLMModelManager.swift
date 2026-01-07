import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// Manages the lifecycle of the LLM model (loading, inference, unloading)
///
/// NOTE: This is a stub implementation. The actual llama.cpp integration requires
/// additional C++ interop configuration. For now, this manager returns placeholder
/// errors. The MockLLMService should be used for testing and development.
final class LLMModelManager: @unchecked Sendable {
    static let shared = LLMModelManager()

    private let queue = DispatchQueue(label: "com.pulse.llm", qos: .userInitiated)
    private let logger = Logger.shared
    private let logCategory = "LLMModelManager"

    private var isLoaded = false

    private init() {
        setupMemoryWarningObserver()
    }

    /// Load the GGUF model into memory
    ///
    /// - Note: Stub implementation - actual llama.cpp integration pending
    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: LLMError.serviceUnavailable)
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
                guard let modelURL = LLMConfiguration.modelURL,
                      FileManager.default.fileExists(atPath: modelURL.path)
                else {
                    // Model file not bundled yet - this is expected during development
                    self.logger.info("Model file not found - using stub implementation", category: self.logCategory)
                    continuation.resume(throwing: LLMError.modelLoadFailed(
                        "Model file not bundled. Please add the GGUF model to Resources/Models/"
                    ))
                    return
                }

                progressHandler(0.5)

                // TODO: Integrate llama.cpp when C++ interop is configured
                // For now, simulate successful load for testing
                self.isLoaded = true
                progressHandler(1.0)
                self.logger.info("Model loaded (stub)", category: self.logCategory)
                continuation.resume()
            }
        }
    }

    /// Unload model and free memory
    func unloadModel() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.isLoaded = false
                self.logger.info("Model unloaded", category: self.logCategory)
                continuation.resume()
            }
        }
    }

    /// Check if model is currently loaded
    var modelIsLoaded: Bool {
        queue.sync { isLoaded }
    }

    /// Generate tokens from prompt
    ///
    /// - Note: Stub implementation - returns placeholder text
    func generate(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        stopSequences _: [String]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: LLMError.serviceUnavailable)
                return
            }

            queue.async {
                guard self.isLoaded else {
                    continuation.finish(throwing: LLMError.modelNotLoaded)
                    return
                }

                // Stub: Generate placeholder response
                // In production, this will use llama.cpp for actual inference
                let stubResponse = """
                [AI Digest - Stub Response]

                This is a placeholder response from the LLM stub implementation.

                To enable actual AI generation:
                1. Bundle a GGUF model in Resources/Models/
                2. Configure C++ interop for llama.cpp
                3. Update LLMModelManager with actual inference code

                The prompt contained \(prompt.count) characters.
                Max tokens requested: \(maxTokens)
                Temperature: \(temperature)
                Top-P: \(topP)
                """

                // Stream the response word by word
                let words = stubResponse.split(separator: " ")
                for (index, word) in words.enumerated() {
                    if Task.isCancelled {
                        continuation.finish(throwing: LLMError.generationCancelled)
                        return
                    }

                    let text = String(word) + (index < words.count - 1 ? " " : "")
                    continuation.yield(text)

                    // Simulate token generation delay
                    Thread.sleep(forTimeInterval: 0.02)
                }

                continuation.finish()
            }
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
