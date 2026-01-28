import Foundation
import llama

public struct Configuration {
    static let historySize = 5
    public let seed: Int
    public let topK: Int
    public let topP: Float
    public let nCTX: Int
    public let temperature: Float
    public let maxTokenCount: Int
    public let batchSize: Int
    public let stopTokens: [String]
    /// Timeout for inference operations in seconds
    public let timeout: TimeInterval

    public init(seed: Int = 1234,
                topK: Int = 40,
                topP: Float = 0.9,
                nCTX: Int = 2048,
                temperature: Float = 0.2,
                batchSize: Int = 2048,
                stopSequence _: String? = nil,
                maxTokenCount: Int = 1024,
                stopTokens: [String] = [],
                timeout: TimeInterval = 30.0)
    {
        self.seed = seed
        self.topK = topK
        self.topP = topP
        self.nCTX = nCTX
        self.batchSize = batchSize
        self.temperature = temperature
        self.maxTokenCount = maxTokenCount
        self.stopTokens = stopTokens
        self.timeout = timeout
    }
}

extension Configuration {
    var contextParameters: ContextParameters {
        var params = llama_context_default_params()
        // Use more threads on capable devices (modern iPhones have 6 cores)
        let cores = ProcessInfo.processInfo.processorCount
        let threadCount = max(1, min(cores - 1, 6))
        params.n_ctx = max(8, UInt32(nCTX)) // minimum context size is 8
        params.n_threads = Int32(threadCount)
        params.n_threads_batch = Int32(threadCount)
        // Flash attention enabled for 10-15% throughput improvement on Metal
        // Note: Previously disabled due to Q4_K_M crashes, but llama.cpp Metal support
        // has been stabilized. If crashes occur, set to false as fallback.
        params.flash_attn = true
        return params
    }
}
