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
        let articles = generateMockArticles(count: 30)
        let capped = FeedDigestPromptBuilder.cappedArticles(from: articles)

        #expect(capped.count <= LLMConfiguration.maxArticlesForDigest)
    }

    @Test("Capped articles balances across categories")
    func cappedArticlesBalancesCategories() {
        let maxPerCat = LLMConfiguration.maxArticlesPerCategory
        let techArticles = generateMockArticles(count: 10, category: .technology)
        let worldArticles = generateMockArticles(
            count: 10, category: .world, idPrefix: "world"
        )
        let all = (techArticles + worldArticles).sorted { $0.publishedAt > $1.publishedAt }
        let capped = FeedDigestPromptBuilder.cappedArticles(from: all)

        let techCount = capped.filter { $0.category == .technology }.count
        let worldCount = capped.filter { $0.category == .world }.count

        // Each category should get at least maxPerCategory articles
        #expect(techCount >= maxPerCat)
        #expect(worldCount >= maxPerCat)
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

        // Should list categories and instruct prose format
        #expect(prompt.contains("**CategoryName**"))
        #expect(prompt.contains("Summarize into flowing paragraphs"))
    }

    @Test("System prompt provides clear instructions")
    func systemPromptIsConfigured() {
        let systemPrompt = FeedDigestPromptBuilder.systemPrompt

        #expect(!systemPrompt.isEmpty)
        #expect(systemPrompt.contains("news digest"))
        #expect(systemPrompt.contains("**CategoryName**"))
        #expect(systemPrompt.contains("DO NOT list"))
    }

    // MARK: - Helpers

    private func generateMockArticles(
        count: Int,
        category: NewsCategory = .technology,
        idPrefix: String = "test"
    ) -> [Article] {
        (0 ..< count).map { index in
            Article(
                id: "\(idPrefix)-\(index)",
                title: "Test Article \(index)",
                description: "Description for article \(index)",
                content: "Content for article \(index)",
                author: "Author \(index)",
                source: ArticleSource(id: "test-source", name: "Test Source"),
                url: "https://example.com/\(idPrefix)-\(index)",
                imageURL: nil,
                publishedAt: Date().addingTimeInterval(Double(-index * 3600)),
                category: category
            )
        }
    }
}
