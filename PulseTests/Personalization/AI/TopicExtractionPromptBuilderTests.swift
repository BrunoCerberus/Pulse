import Foundation
@testable import Pulse
import Testing

@Suite("TopicExtractionPromptBuilder Tests")
struct TopicExtractionPromptBuilderTests {
    // MARK: - parseTags

    @Test("Parses a clean comma-separated list")
    func parsesCleanList() {
        let raw = "artificial-intelligence, climate-change, renewable-energy"
        #expect(TopicExtractionPromptBuilder.parseTags(from: raw) == [
            "artificial-intelligence",
            "climate-change",
            "renewable-energy",
        ])
    }

    @Test("Lowercases mixed-case input")
    func lowercasesMixedCase() {
        let raw = "Artificial-Intelligence, ClimateChange"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags.contains("artificial-intelligence"))
        #expect(tags.contains("climatechange"))
    }

    @Test("Replaces underscores and spaces with hyphens")
    func replacesUnderscoresAndSpaces() {
        let raw = "artificial intelligence, machine_learning"
        #expect(TopicExtractionPromptBuilder.parseTags(from: raw) == [
            "artificial-intelligence",
            "machine-learning",
        ])
    }

    @Test("Strips code-fence wrappers")
    func stripsCodeFences() {
        let raw = "```\nai, climate, energy\n```"
        #expect(TopicExtractionPromptBuilder.parseTags(from: raw) == [
            "ai",
            "climate",
            "energy",
        ])
    }

    @Test("Strips language-tagged code fences")
    func stripsLanguageCodeFences() {
        let raw = "```text\nai, climate\n```"
        #expect(TopicExtractionPromptBuilder.parseTags(from: raw) == ["ai", "climate"])
    }

    @Test("Caps output at 5 tags")
    func capsAtFiveTags() {
        let raw = "a-tag, b-tag, c-tag, d-tag, e-tag, f-tag, g-tag"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags.count == 5)
    }

    @Test("Filters tags shorter than 2 characters")
    func filtersTooShort() {
        let raw = "a, ai, technology"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags == ["ai", "technology"])
    }

    @Test("Filters tags longer than 50 characters")
    func filtersTooLong() {
        let longTag = String(repeating: "a", count: 51)
        let raw = "\(longTag), valid-tag"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags == ["valid-tag"])
    }

    @Test("Deduplicates repeated tags")
    func deduplicates() {
        let raw = "ai, ai, climate, climate, climate"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags == ["ai", "climate"])
    }

    @Test("Strips surrounding quotes and punctuation")
    func stripsQuotes() {
        let raw = "\"ai\", 'climate', `energy`"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(Set(tags) == ["ai", "climate", "energy"])
    }

    @Test("Drops trailing commentary on later lines")
    func dropsTrailingCommentary() {
        let raw = "ai, climate\nThese tags describe the article."
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags == ["ai", "climate"])
    }

    @Test("Returns empty array for empty input")
    func emptyInput() {
        #expect(TopicExtractionPromptBuilder.parseTags(from: "").isEmpty)
        #expect(TopicExtractionPromptBuilder.parseTags(from: "   \n  ").isEmpty)
    }

    @Test("Returns empty array for input with no valid tags")
    func noValidTags() {
        let raw = "?, !, ., ,"
        #expect(TopicExtractionPromptBuilder.parseTags(from: raw).isEmpty)
    }

    @Test("Collapses repeated hyphens")
    func collapsesRepeatedHyphens() {
        let raw = "artificial--intelligence, climate---change"
        let tags = TopicExtractionPromptBuilder.parseTags(from: raw)
        #expect(tags == ["artificial-intelligence", "climate-change"])
    }

    // MARK: - displayName

    @Test("displayName converts kebab-case to Title Case")
    func displayNameTitleCase() {
        #expect(TopicExtractionPromptBuilder.displayName(for: "artificial-intelligence") == "Artificial Intelligence")
        #expect(TopicExtractionPromptBuilder.displayName(for: "ai") == "Ai")
        #expect(TopicExtractionPromptBuilder.displayName(for: "climate-change-2030") == "Climate Change 2030")
    }

    // MARK: - buildPrompt

    @Test("buildPrompt includes title and summary when both present")
    func buildPromptIncludesBoth() {
        let prompt = TopicExtractionPromptBuilder.buildPrompt(
            title: "Apple announces M4",
            summary: "Apple unveiled its new chip."
        )
        #expect(prompt.contains("Apple announces M4"))
        #expect(prompt.contains("Apple unveiled its new chip."))
    }

    @Test("buildPrompt omits summary section when nil or empty")
    func buildPromptOmitsEmptySummary() {
        let nilSummary = TopicExtractionPromptBuilder.buildPrompt(title: "T", summary: nil)
        let emptySummary = TopicExtractionPromptBuilder.buildPrompt(title: "T", summary: "")
        #expect(!nilSummary.contains("Summary:"))
        #expect(!emptySummary.contains("Summary:"))
    }
}
