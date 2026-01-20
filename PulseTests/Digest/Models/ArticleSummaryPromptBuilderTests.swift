import Foundation
@testable import Pulse
import Testing

@Suite("ArticleSummaryPromptBuilder Tests")
struct ArticleSummaryPromptBuilderTests {
    @Test("System prompt is defined")
    func systemPromptIsDefined() {
        let prompt = ArticleSummaryPromptBuilder.systemPrompt
        #expect(!prompt.isEmpty)
        #expect(prompt.contains("concise"))
    }

    @Test("Build prompt includes article title")
    func buildPromptIncludesTitle() {
        let article = Article.mockArticles.first!
        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains(article.title))
    }

    @Test("Build prompt includes article source")
    func buildPromptIncludesSource() {
        let article = Article.mockArticles.first!
        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains(article.source.name))
    }

    @Test("Build prompt strips HTML from description")
    func buildPromptStripsHTMLFromDescription() {
        let article = Article(
            id: "test-1",
            title: "Test Title",
            description: "<p>This is <strong>important</strong> news</p>",
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(!prompt.contains("<p>"))
        #expect(!prompt.contains("<strong>"))
    }

    @Test("Build prompt handles empty description")
    func buildPromptHandlesEmptyDescription() {
        let article = Article(
            id: "test-2",
            title: "Test Title",
            description: "",
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains(article.title))
    }

    @Test("Build prompt handles nil description")
    func buildPromptHandlesNilDescription() {
        let article = Article(
            id: "test-3",
            title: "Test Title",
            description: nil,
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains(article.title))
    }

    @Test("Build prompt truncates long content")
    func buildPromptTruncatesLongContent() {
        let longContent = String(repeating: "A", count: 2000)
        let article = Article(
            id: "test-4",
            title: "Test Title",
            description: "Test description",
            content: longContent,
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(!prompt.isEmpty)
    }

    @Test("HTML stripping handles common entities")
    func htmlStrippingHandlesCommonEntities() {
        let article = Article(
            id: "test-5",
            title: "Test Title",
            description: "&amp;&lt;&gt;&quot;&#39;&nbsp;",
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(!prompt.contains("&amp;"))
        #expect(!prompt.contains("&lt;"))
        #expect(!prompt.contains("&gt;"))
    }

    @Test("Build prompt handles empty article")
    func buildPromptHandlesEmptyArticle() {
        let article = Article(
            id: "test-6",
            title: "Test",
            description: "",
            content: "",
            source: .init(id: "source", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date()
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains(article.title))
    }
}
