import Foundation

/// Configuration for the bundled LLM model
enum LLMConfiguration {
    /// Model file name without extension
    /// Note: Download from https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF
    static var modelFileName: String { "Llama-3.2-1B-Instruct-Q4_K_M" }

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

    /// Maximum articles to include in digest prompt
    /// Capped to prevent context overflow and ensure reasonable generation time
    /// ~250 tokens per article, leaving room for system prompt (~100) and output (~1000)
    static var maxArticlesForDigest: Int { 10 }

    /// Estimated tokens per article in digest prompt
    static var estimatedTokensPerArticle: Int { 250 }

    /// Reserved tokens for system prompt and generation output
    static var reservedContextTokens: Int { 1500 }
}
