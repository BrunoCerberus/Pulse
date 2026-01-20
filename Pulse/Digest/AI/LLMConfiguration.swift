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

    /// Context window size (tokens) - reduced for faster inference
    static var contextSize: Int { 3072 }

    /// Batch size for inference, scaled by device memory
    /// - 4GB+ RAM: 2048 (optimal throughput)
    /// - <4GB RAM: 512 (safe for older devices)
    static var batchSize: Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let fourGB: UInt64 = 4_000_000_000
        return physicalMemory >= fourGB ? 2048 : 512
    }

    /// Number of threads to use (based on device)
    static var threadCount: Int {
        min(ProcessInfo.processInfo.activeProcessorCount, 4)
    }

    /// Minimum available memory required to load model (1GB)
    static var minimumAvailableMemory: UInt64 { 1_000_000_000 }

    /// Generation timeout in seconds
    static var generationTimeout: TimeInterval { 120.0 }

    /// Maximum articles to include in digest prompt
    /// Capped to prevent context overflow: 8 × 175 + 1500 reserved = 2900 < 3072 context
    static var maxArticlesForDigest: Int { 8 }

    /// Estimated tokens per article in digest prompt (title + source + category + 150 char description)
    /// ~15 title + ~3 source + ~2 category + ~37 description (150 chars / 4) + ~5 structure ≈ 62
    /// Using 175 as conservative estimate with safety margin
    static var estimatedTokensPerArticle: Int { 175 }

    /// Reserved tokens for system prompt and generation output
    static var reservedContextTokens: Int { 1500 }
}
