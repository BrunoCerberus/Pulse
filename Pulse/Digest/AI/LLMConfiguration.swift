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

    /// Batch size for prompt processing
    /// Larger batch = faster prompt ingestion (prompt tokens processed in parallel)
    /// Token generation is sequential, so batch size doesn't affect generation speed
    static var batchSize: Int {
        let memory = ProcessInfo.processInfo.physicalMemory
        // Devices with 4GB+ RAM can use larger batches for faster prompt processing
        if memory >= 4_000_000_000 {
            return 2048
        }
        return 512
    }

    /// Number of threads to use (based on device capabilities)
    /// Modern iPhones have 6 cores - use most of them for inference
    static var threadCount: Int {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        // Use up to 6 threads on capable devices, leaving some headroom
        return min(cores - 1, 6)
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
