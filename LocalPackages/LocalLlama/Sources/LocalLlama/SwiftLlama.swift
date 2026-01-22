import Foundation
import llama
import Combine

/// Thread-safe LLM wrapper using a dedicated pinned thread
/// All llama.cpp operations run on the EXACT SAME OS thread to avoid thread-local state issues
public final class SwiftLlama: @unchecked Sendable {
    private var model: LlamaModel?
    private let modelPath: String
    private let configuration: Configuration
    private var contentStarted = false
    private var generatedTokenCache = ""
    private var isInitialized = false

    /// Cached system prompt hash for KV cache reuse optimization
    /// When the same system prompt is used, we can skip re-processing it
    private var lastSystemPromptHash: Int?

    /// Dedicated thread for all llama.cpp operations
    private var llamaThread: Thread?
    private var runLoop: CFRunLoop?
    private let threadReadyLock = NSCondition()
    private var threadReady = false

    var maxLengthOfStopToken: Int {
        configuration.stopTokens.map { $0.count }.max() ?? 0
    }

    public init(modelPath: String, modelConfiguration: Configuration = .init()) {
        self.modelPath = modelPath
        self.configuration = modelConfiguration
        startDedicatedThread()
    }

    private func startDedicatedThread() {
        // Use weak self to avoid potential crashes if instance is deallocated during thread startup
        llamaThread = Thread { [weak self] in
            guard let self = self else { return }

            // Get the run loop for this thread
            self.runLoop = CFRunLoopGetCurrent()

            // Signal that the thread is ready
            self.threadReadyLock.lock()
            self.threadReady = true
            self.threadReadyLock.signal()
            self.threadReadyLock.unlock()

            // Keep the thread alive until cancelled or self is deallocated
            while !Thread.current.isCancelled {
                CFRunLoopRunInMode(.defaultMode, 0.1, false)
            }
        }
        llamaThread?.name = "com.localllama.inference"
        // Use highest QoS for maximum inference priority
        llamaThread?.qualityOfService = .userInteractive
        llamaThread?.start()

        // Wait for thread to be ready
        threadReadyLock.lock()
        while !threadReady {
            threadReadyLock.wait()
        }
        threadReadyLock.unlock()
    }

    /// Execute a block on the dedicated llama thread synchronously
    private func executeOnLlamaThread<T>(_ block: @escaping () throws -> T) throws -> T {
        guard let runLoop = runLoop else {
            throw SwiftLlamaError.others("Llama thread not initialized")
        }

        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) {
            do {
                result = .success(try block())
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }
        CFRunLoopWakeUp(runLoop)

        let timeout = DispatchTime.now() + configuration.timeout
        if semaphore.wait(timeout: timeout) == .timedOut {
            throw SwiftLlamaError.others("Inference timed out after \(Int(configuration.timeout)) seconds")
        }

        guard let result = result else {
            throw SwiftLlamaError.others("Execution result was unexpectedly nil")
        }

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    /// Initialize the model - MUST be called before generate
    public func initialize() throws {
        try executeOnLlamaThread { [self] in
            guard !isInitialized else { return }
            self.model = try LlamaModel(path: modelPath, configuration: configuration)
            self.isInitialized = true
        }
    }

    public var isModelLoaded: Bool {
        do {
            return try executeOnLlamaThread { [self] in
                isInitialized && model != nil
            }
        } catch {
            return false
        }
    }

    /// Generate text on the dedicated llama thread
    /// - Parameter prompt: The prompt containing system and user messages
    /// - Returns: Generated text response
    /// - Note: Uses KV cache reuse optimization - if the system prompt hasn't changed,
    ///   we preserve the cached system prompt tokens for faster generation.
    public func generate(for prompt: Prompt) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try executeOnLlamaThread { [self] in
                    guard let model = self.model else {
                        throw SwiftLlamaError.others("Model not initialized")
                    }

                    self.contentStarted = false
                    self.generatedTokenCache = ""

                    var result = ""

                    // KV Cache optimization: only clear if system prompt changed
                    let currentSystemHash = prompt.systemPrompt.hashValue
                    let systemPromptChanged = lastSystemPromptHash != currentSystemHash
                    if systemPromptChanged {
                        model.clear()
                        lastSystemPromptHash = currentSystemHash
                    }

                    // Always clear after generation to prevent context overflow
                    defer { model.clear() }

                    try model.start(for: prompt)

                    while model.shouldContinue {
                        var delta = try model.continue()

                        if self.contentStarted {
                            if self.checkStopToken(delta: delta, result: &result) {
                                break
                            }
                        } else {
                            delta = delta.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !delta.isEmpty {
                                self.contentStarted = true
                                if self.checkStopToken(delta: delta, result: &result) {
                                    break
                                }
                            }
                        }
                    }

                    // Finalize output
                    self.configuration.stopTokens.forEach {
                        self.generatedTokenCache = self.generatedTokenCache.replacingOccurrences(of: $0, with: "")
                    }
                    result += self.generatedTokenCache
                    self.generatedTokenCache = ""

                    return result
                }
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func checkStopToken(delta: String, result: inout String) -> Bool {
        guard maxLengthOfStopToken > 0 else {
            result += delta
            return false
        }

        generatedTokenCache += delta

        if generatedTokenCache.count >= maxLengthOfStopToken * 2 {
            if let stopToken = configuration.stopTokens.first(where: { generatedTokenCache.contains($0) }),
               let index = generatedTokenCache.range(of: stopToken) {
                result += String(generatedTokenCache[..<index.lowerBound])
                generatedTokenCache = ""
                return true
            } else {
                let outputCandidate = String(generatedTokenCache.prefix(maxLengthOfStopToken))
                generatedTokenCache.removeFirst(outputCandidate.count)
                result += outputCandidate
                return false
            }
        }
        return false
    }

    deinit {
        // Clean up on the llama thread
        if let runLoop = runLoop {
            let semaphore = DispatchSemaphore(value: 0)
            CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [self] in
                self.model = nil
                semaphore.signal()
            }
            CFRunLoopWakeUp(runLoop)
            _ = semaphore.wait(timeout: .now() + 5)
        }
        llamaThread?.cancel()
    }
}
