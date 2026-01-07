import Foundation

/// Configuration for the bundled LLM model
enum LLMConfiguration {
    /// Model file name without extension
    static var modelFileName: String { "llama-3.2-1b-instruct-q4_k_m" }

    /// Model file extension
    static var modelExtension: String { "gguf" }

    /// Full model URL within app bundle
    static var modelURL: URL? {
        Bundle.main.url(forResource: modelFileName, withExtension: modelExtension)
    }

    /// Model file path
    static var modelPath: String {
        modelURL?.path ?? ""
    }

    /// Context window size (tokens)
    static var contextSize: Int { 4096 }

    /// Batch size for inference
    static var batchSize: Int { 512 }

    /// Number of threads to use (based on device)
    static var threadCount: Int {
        min(ProcessInfo.processInfo.activeProcessorCount, 4)
    }

    /// Minimum available memory required to load model (1GB)
    static var minimumAvailableMemory: UInt64 { 1_000_000_000 }

    /// Generation timeout in seconds
    static var generationTimeout: TimeInterval { 30.0 }
}
