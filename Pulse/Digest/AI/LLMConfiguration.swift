import Foundation

// MARK: - Memory Tier

/// Memory tier for adaptive LLM configuration based on device physical memory.
/// Prevents crashes on constrained devices by scaling parameters appropriately.
enum MemoryTier: String {
    case constrained // < 4GB (iPhone SE 2020, older devices)
    case standard // 4-6GB (most modern iPhones)
    case high // > 6GB (Pro/Max models)

    /// Returns the current device's memory tier
    static var current: MemoryTier {
        let memoryInGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        switch memoryInGB {
        case ..<4: return .constrained
        case 4 ..< 6: return .standard
        default: return .high
        }
    }

    /// Human-readable description for logging
    var description: String {
        switch self {
        case .constrained: return "constrained (<4GB)"
        case .standard: return "standard (4-6GB)"
        case .high: return "high (>6GB)"
        }
    }
}

// MARK: - LLM Configuration

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

    /// Context window size (tokens) - memory-adaptive for device safety
    /// - Constrained: 2048 (prevents OOM on 3GB devices)
    /// - Standard: 3072 (balanced for most iPhones)
    /// - High: 4096 (full capacity for Pro models)
    static var contextSize: Int {
        switch MemoryTier.current {
        case .constrained: return 2048
        case .standard: return 3072
        case .high: return 4096
        }
    }

    /// Batch size for prompt processing - memory-adaptive
    /// Larger batch = faster prompt ingestion (prompt tokens processed in parallel)
    /// Token generation is sequential, so batch size doesn't affect generation speed
    static var batchSize: Int {
        switch MemoryTier.current {
        case .constrained: return 256
        case .standard: return 512
        case .high: return 2048
        }
    }

    /// Number of threads to use (based on device capabilities)
    /// Modern iPhones have 6 cores - use most of them for inference
    static var threadCount: Int {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        // Use up to 6 threads on capable devices, leaving some headroom
        return min(cores - 1, 6)
    }

    /// Minimum available memory required to load model - memory-adaptive
    /// - Constrained: 1.5GB (stricter threshold to prevent crashes)
    /// - Standard: 1.2GB
    /// - High: 1.0GB (more permissive for high-memory devices)
    static var minimumAvailableMemory: UInt64 {
        switch MemoryTier.current {
        case .constrained: return 1_500_000_000 // 1.5GB
        case .standard: return 1_200_000_000 // 1.2GB
        case .high: return 1_000_000_000 // 1.0GB
        }
    }

    /// Minimum available memory required for inference (less than model load)
    /// Inference requires less headroom since model is already loaded
    static var minimumInferenceMemory: UInt64 {
        switch MemoryTier.current {
        case .constrained: return 800_000_000 // 800MB
        case .standard: return 600_000_000 // 600MB
        case .high: return 500_000_000 // 500MB
        }
    }

    /// Generation timeout in seconds
    static var generationTimeout: TimeInterval { 120.0 }

    /// Maximum articles to include in digest prompt - memory-adaptive
    /// Scales with context size to prevent overflow
    static var maxArticlesForDigest: Int {
        switch MemoryTier.current {
        case .constrained: return 5
        case .standard: return 8
        case .high: return 10
        }
    }

    /// Estimated tokens per article in digest prompt (title + source + category + 150 char description)
    /// ~15 title + ~3 source + ~2 category + ~37 description (150 chars / 4) + ~5 structure ≈ 62
    /// Using 175 as conservative estimate with safety margin
    static var estimatedTokensPerArticle: Int { 175 }

    /// Reserved tokens for system prompt and generation output
    static var reservedContextTokens: Int { 1500 }
}
