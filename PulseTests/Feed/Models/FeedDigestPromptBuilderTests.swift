import Foundation
@testable import Pulse
import Testing

@Suite("FeedDigestPromptBuilder Tests")
struct FeedDigestPromptBuilderTests {
    // MARK: - Article Capping Tests

    @Test("Capped articles returns all when under limit")
    func cappedArticlesUnderLimit() {
        let articles = Article.mockArticles // 5 articles
        let capped = FeedDigestPromptBuilder.cappedArticles(from: articles)

        #expect(capped.count == articles.count)
        #expect(capped.map(\.id) == articles.map(\.id))
    }

    @Test("Capped articles limits to max when over limit")
    func cappedArticlesOverLimit() {
        let articles = generateMockArticles(count: 20)
        let capped = FeedDigestPromptBuilder.cappedArticles(from: articles)

        #expect(capped.count == LLMConfiguration.maxArticlesForDigest)
        // Should take the first N (most recent) articles
        let expectedIds = articles.prefix(LLMConfiguration.maxArticlesForDigest).map(\.id)
        #expect(capped.map(\.id) == expectedIds)
    }

    @Test("Capped articles handles empty array")
    func cappedArticlesEmpty() {
        let capped = FeedDigestPromptBuilder.cappedArticles(from: [])
        #expect(capped.isEmpty)
    }

    @Test("Capped articles handles exactly at limit")
    func cappedArticlesAtLimit() {
        let articles = generateMockArticles(count: LLMConfiguration.maxArticlesForDigest)
        let capped = FeedDigestPromptBuilder.cappedArticles(from: articles)

        #expect(capped.count == LLMConfiguration.maxArticlesForDigest)
        #expect(capped.map(\.id) == articles.map(\.id))
    }

    // MARK: - Token Estimation Tests

    @Test("Token estimation increases with article count")
    func tokenEstimationScales() {
        let fiveArticles = generateMockArticles(count: 5)
        let tenArticles = generateMockArticles(count: 10)

        let fiveTokens = FeedDigestPromptBuilder.estimatedTokenCount(for: fiveArticles)
        let tenTokens = FeedDigestPromptBuilder.estimatedTokenCount(for: tenArticles)

        #expect(tenTokens > fiveTokens)
    }

    @Test("Token estimation for empty array returns base overhead")
    func tokenEstimationEmpty() {
        let tokens = FeedDigestPromptBuilder.estimatedTokenCount(for: [])
        #expect(tokens > 0) // Should have system prompt + overhead tokens
        #expect(tokens < 200) // But not too many
    }

    // MARK: - Prompt Building Tests

    @Test("Build prompt includes all article titles")
    func buildPromptIncludesAllTitles() {
        let articles = Article.mockArticles
        let prompt = FeedDigestPromptBuilder.buildPrompt(for: articles)

        for article in articles {
            #expect(prompt.contains(article.title))
        }
    }

    @Test("Build prompt includes numbered article list")
    func buildPromptIncludesNumberedList() {
        let articles = Article.mockArticles
        let prompt = FeedDigestPromptBuilder.buildPrompt(for: articles)

        #expect(prompt.contains("1."))
        #expect(prompt.contains("Articles:"))
    }

    @Test("Build prompt includes category names for digest")
    func buildPromptIncludesCategoryNames() {
        let articles = Article.mockArticles
        let prompt = FeedDigestPromptBuilder.buildPrompt(for: articles)

        // Should list categories for the model to use as headers
        #expect(prompt.contains("**CategoryName**"))
        #expect(prompt.contains("Write a digest"))
    }

    @Test("System prompt provides clear instructions")
    func systemPromptIsConfigured() {
        let systemPrompt = FeedDigestPromptBuilder.systemPrompt

        #expect(!systemPrompt.isEmpty)
        #expect(systemPrompt.contains("news digests"))
        #expect(systemPrompt.contains("**CategoryName**"))
    }

    // MARK: - Helpers

    private func generateMockArticles(count: Int) -> [Article] {
        (0 ..< count).map { index in
            Article(
                id: "test-\(index)",
                title: "Test Article \(index)",
                description: "Description for article \(index)",
                content: "Content for article \(index)",
                author: "Author \(index)",
                source: ArticleSource(id: "test-source", name: "Test Source"),
                url: "https://example.com/\(index)",
                imageURL: nil,
                publishedAt: Date().addingTimeInterval(Double(-index * 3600)),
                category: .technology
            )
        }
    }
}
