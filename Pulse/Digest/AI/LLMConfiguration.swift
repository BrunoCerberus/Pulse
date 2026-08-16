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
        case .constrained: "constrained (<4GB)"
        case .standard: "standard (4-6GB)"
        case .high: "high (>6GB)"
        }
    }
}

// MARK: - LLM Configuration

/// Configuration for the on-device LLM model
enum LLMConfiguration {
    /// Model file name without extension.
    static var modelFileName: String {
        "gemma-3-1b-it-Q4_K_M"
    }

    /// Model file extension
    static var modelExtension: String {
        "gguf"
    }

    /// File name as published in the Hugging Face repository, which differs
    /// from the local ``modelFileName``.
    static var remoteModelFileName: String {
        "google_gemma-3-1b-it-Q4_K_M"
    }

    /// Repository revision the pinned size and hash were taken from. `main` is
    /// mutable, so a re-upload there would fail integrity checks forever with
    /// no client-side remedy; a commit SHA is immutable.
    static var modelRepositoryRevision: String {
        "116f76234503685a98f572982177b11d44ec8ff1"
    }

    /// URL used for the first-use model download.
    static var modelDownloadURL: URL {
        let urlString = "https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/"
            + "\(modelRepositoryRevision)/\(remoteModelFileName).\(modelExtension)?download=true"
        return URL(string: urlString)!
    }

    /// Expected size of the pinned Gemma quantization in bytes.
    static var modelSizeBytes: UInt64 {
        806_058_496
    }

    /// Expected SHA-256 for the pinned Gemma quantization.
    static var modelSHA256: String {
        "12bf0fff8815d5f73a3c9b586bd8fee8e7b248c935de70dec367679873d0f29d"
    }

    /// Persistent on-device location for the downloaded model.
    static var downloadedModelURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pulse/Models", isDirectory: true)
            .appendingPathComponent("\(modelFileName).\(modelExtension)")
    }

    /// Context window size (tokens) - memory-adaptive for device safety
    /// - Constrained: 4096 (conservative to balance speed and memory)
    /// - Standard/High: 8192 (balanced performance vs speed)
    /// Note: Gemma 3 supports up to 32K context but we cap for on-device inference speed
    static var contextSize: Int {
        switch MemoryTier.current {
        case .constrained: 4096
        case .standard, .high: 8192
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
        case .constrained: 1_500_000_000 // 1.5GB
        case .standard: 1_200_000_000 // 1.2GB
        case .high: 1_000_000_000 // 1.0GB
        }
    }

    /// Minimum available memory required for inference (less than model load)
    /// Inference requires less headroom since model is already loaded
    static var minimumInferenceMemory: UInt64 {
        switch MemoryTier.current {
        case .constrained: 800_000_000 // 800MB
        case .standard: 600_000_000 // 600MB
        case .high: 500_000_000 // 500MB
        }
    }

    /// Sampling temperature for inference
    /// Lower values (0.3-0.5) produce more factual/consistent output for summarization
    /// Higher values (0.7-0.9) produce more creative/varied output
    static var temperature: Float {
        0.5
    }

    /// Generation timeout in seconds
    static var generationTimeout: TimeInterval {
        120.0
    }

    /// Maximum articles to include in digest prompt - memory-adaptive
    /// Scales with context size to prevent overflow
    /// Higher caps give the model more material per category for richer summaries
    static var maxArticlesForDigest: Int {
        switch MemoryTier.current {
        case .constrained: 15
        case .standard, .high: 25
        }
    }

    /// Maximum articles to include per category for balanced digest coverage
    static var maxArticlesPerCategory: Int {
        switch MemoryTier.current {
        case .constrained: 3
        case .standard, .high: 4
        }
    }

    /// Estimated tokens per article in digest prompt (title + source + category + 250 char description)
    /// ~15 title + ~3 source + ~2 category + ~63 description (250 chars / 4) + ~5 structure ≈ 88
    /// Using 100 as estimate with modest safety margin
    static var estimatedTokensPerArticle: Int {
        100
    }

    /// Maximum output tokens for generation
    /// Gemma 3 1B handles longer outputs well with its 32K context window
    static var maxOutputTokens: Int {
        switch MemoryTier.current {
        case .constrained: 1024
        case .standard, .high: 2048
        }
    }

    /// Maximum paragraphs per category section in parsed digest output
    static var maxParagraphsPerSection: Int {
        3
    }

    /// Reserved tokens for system prompt and generation output
    static var reservedContextTokens: Int {
        1500
    }
}
