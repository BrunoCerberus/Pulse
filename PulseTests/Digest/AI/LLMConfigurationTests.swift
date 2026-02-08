import Foundation
@testable import Pulse
import Testing

// MARK: - MemoryTier Tests

@Suite("MemoryTier Tests")
struct MemoryTierTests {
    @Test("MemoryTier has all cases")
    func hasAllCases() {
        let allCases: [MemoryTier] = [.constrained, .standard, .high]
        #expect(allCases.count == 3)
    }

    @Test("MemoryTier raw values are correct")
    func rawValuesAreCorrect() {
        #expect(MemoryTier.constrained.rawValue == "constrained")
        #expect(MemoryTier.standard.rawValue == "standard")
        #expect(MemoryTier.high.rawValue == "high")
    }

    @Test("MemoryTier description returns correct strings")
    func descriptionReturnsCorrectStrings() {
        #expect(MemoryTier.constrained.description == "constrained (<4GB)")
        #expect(MemoryTier.standard.description == "standard (4-6GB)")
        #expect(MemoryTier.high.description == "high (>6GB)")
    }

    @Test("MemoryTier current returns valid tier")
    func currentReturnsValidTier() {
        let current = MemoryTier.current
        // Should be one of the valid cases
        #expect(
            current == .constrained || current == .standard || current == .high,
            "Current memory tier should be a valid case"
        )
    }
}

// MARK: - LLMConfiguration Tests

@Suite("LLMConfiguration Tests")
struct LLMConfigurationTests {
    // MARK: - Model File Tests

    @Test("LLMConfiguration modelFileName returns correct value")
    func modelFileNameReturnsCorrectValue() {
        #expect(LLMConfiguration.modelFileName == "LFM2.5-1.2B-Instruct-Q4_K_M")
    }

    @Test("LLMConfiguration modelExtension returns correct value")
    func modelExtensionReturnsCorrectValue() {
        #expect(LLMConfiguration.modelExtension == "gguf")
    }

    // MARK: - Context Size Tests

    @Test("LLMConfiguration contextSize returns valid value")
    func contextSizeReturnsValidValue() {
        let contextSize = LLMConfiguration.contextSize
        // Context size should be either 4096 (constrained) or 8192 (standard/high)
        #expect(contextSize == 4096 || contextSize == 8192)
    }

    @Test("LLMConfiguration contextSize values match memory tiers")
    func contextSizeMatchesMemoryTiers() {
        // Based on the tier, verify the expected context size
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.contextSize == 4096)
        case .standard, .high:
            #expect(LLMConfiguration.contextSize == 8192)
        }
    }

    // MARK: - Thread Count Tests

    @Test("LLMConfiguration threadCount returns positive value")
    func threadCountReturnsPositiveValue() {
        let threadCount = LLMConfiguration.threadCount
        #expect(threadCount > 0, "Thread count should be positive")
    }

    @Test("LLMConfiguration threadCount does not exceed 6")
    func threadCountDoesNotExceedSix() {
        let threadCount = LLMConfiguration.threadCount
        #expect(threadCount <= 6, "Thread count should not exceed 6")
    }

    @Test("LLMConfiguration threadCount is based on processor count")
    func threadCountBasedOnProcessorCount() {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let expected = min(cores - 1, 6)
        #expect(LLMConfiguration.threadCount == expected)
    }

    // MARK: - Minimum Available Memory Tests

    @Test("LLMConfiguration minimumAvailableMemory returns valid value")
    func minimumAvailableMemoryReturnsValidValue() {
        let memory = LLMConfiguration.minimumAvailableMemory
        // Should be one of: 1.0GB, 1.2GB, or 1.5GB
        let validValues: [UInt64] = [1_000_000_000, 1_200_000_000, 1_500_000_000]
        #expect(validValues.contains(memory))
    }

    @Test("LLMConfiguration minimumAvailableMemory values match memory tiers")
    func minimumAvailableMemoryMatchesMemoryTiers() {
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.minimumAvailableMemory == 1_500_000_000)
        case .standard:
            #expect(LLMConfiguration.minimumAvailableMemory == 1_200_000_000)
        case .high:
            #expect(LLMConfiguration.minimumAvailableMemory == 1_000_000_000)
        }
    }

    // MARK: - Minimum Inference Memory Tests

    @Test("LLMConfiguration minimumInferenceMemory returns valid value")
    func minimumInferenceMemoryReturnsValidValue() {
        let memory = LLMConfiguration.minimumInferenceMemory
        // Should be one of: 500MB, 600MB, or 800MB
        let validValues: [UInt64] = [500_000_000, 600_000_000, 800_000_000]
        #expect(validValues.contains(memory))
    }

    @Test("LLMConfiguration minimumInferenceMemory values match memory tiers")
    func minimumInferenceMemoryMatchesMemoryTiers() {
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.minimumInferenceMemory == 800_000_000)
        case .standard:
            #expect(LLMConfiguration.minimumInferenceMemory == 600_000_000)
        case .high:
            #expect(LLMConfiguration.minimumInferenceMemory == 500_000_000)
        }
    }

    @Test("LLMConfiguration minimumInferenceMemory is less than minimumAvailableMemory")
    func minimumInferenceMemoryLessThanAvailableMemory() {
        #expect(LLMConfiguration.minimumInferenceMemory < LLMConfiguration.minimumAvailableMemory)
    }

    // MARK: - Generation Timeout Tests

    @Test("LLMConfiguration generationTimeout returns correct value")
    func generationTimeoutReturnsCorrectValue() {
        #expect(LLMConfiguration.generationTimeout == 120.0)
    }

    // MARK: - Max Articles For Digest Tests

    @Test("LLMConfiguration maxArticlesForDigest returns valid value")
    func maxArticlesForDigestReturnsValidValue() {
        let maxArticles = LLMConfiguration.maxArticlesForDigest
        // Should be either 15 (constrained) or 25 (standard/high)
        #expect(maxArticles == 15 || maxArticles == 25)
    }

    @Test("LLMConfiguration maxArticlesForDigest values match memory tiers")
    func maxArticlesForDigestMatchesMemoryTiers() {
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.maxArticlesForDigest == 15)
        case .standard, .high:
            #expect(LLMConfiguration.maxArticlesForDigest == 25)
        }
    }

    @Test("LLMConfiguration maxArticlesForDigest is positive")
    func maxArticlesForDigestIsPositive() {
        #expect(LLMConfiguration.maxArticlesForDigest > 0)
    }

    @Test("LLMConfiguration maxArticlesPerCategory returns valid value")
    func maxArticlesPerCategoryReturnsValidValue() {
        let maxPerCat = LLMConfiguration.maxArticlesPerCategory
        #expect(maxPerCat == 3 || maxPerCat == 4)
    }

    @Test("LLMConfiguration maxArticlesPerCategory values match memory tiers")
    func maxArticlesPerCategoryMatchesMemoryTiers() {
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.maxArticlesPerCategory == 3)
        case .standard, .high:
            #expect(LLMConfiguration.maxArticlesPerCategory == 4)
        }
    }

    // MARK: - Token Estimation Tests

    @Test("LLMConfiguration estimatedTokensPerArticle returns correct value")
    func estimatedTokensPerArticleReturnsCorrectValue() {
        #expect(LLMConfiguration.estimatedTokensPerArticle == 100)
    }

    @Test("LLMConfiguration reservedContextTokens returns correct value")
    func reservedContextTokensReturnsCorrectValue() {
        #expect(LLMConfiguration.reservedContextTokens == 1500)
    }

    @Test("LLMConfiguration reservedContextTokens is less than contextSize")
    func reservedContextTokensLessThanContextSize() {
        #expect(LLMConfiguration.reservedContextTokens < LLMConfiguration.contextSize)
    }

    // MARK: - Max Output Tokens Tests

    @Test("LLMConfiguration maxOutputTokens returns valid value")
    func maxOutputTokensReturnsValidValue() {
        let maxOutput = LLMConfiguration.maxOutputTokens
        #expect(maxOutput == 1024 || maxOutput == 2048)
    }

    @Test("LLMConfiguration maxOutputTokens values match memory tiers")
    func maxOutputTokensMatchesMemoryTiers() {
        switch MemoryTier.current {
        case .constrained:
            #expect(LLMConfiguration.maxOutputTokens == 1024)
        case .standard, .high:
            #expect(LLMConfiguration.maxOutputTokens == 2048)
        }
    }

    @Test("LLMConfiguration maxOutputTokens is less than contextSize")
    func maxOutputTokensLessThanContextSize() {
        #expect(LLMConfiguration.maxOutputTokens < LLMConfiguration.contextSize)
    }

    // MARK: - Max Paragraphs Per Section Tests

    @Test("LLMConfiguration maxParagraphsPerSection returns correct value")
    func maxParagraphsPerSectionReturnsCorrectValue() {
        #expect(LLMConfiguration.maxParagraphsPerSection == 3)
    }
}
