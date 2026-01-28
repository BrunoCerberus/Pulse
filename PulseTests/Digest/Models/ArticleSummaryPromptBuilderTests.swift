import Foundation
@testable import Pulse
import Testing

@Suite("ArticleSummaryPromptBuilder Tests")
struct ArticleSummaryPromptBuilderTests {
    // MARK: - buildPrompt Tests

    @Test("Build prompt includes article title")
    func buildPromptIncludesTitle() {
        let article = Article(
            title: "Test Article Title",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Title: Test Article Title"))
    }

    @Test("Build prompt includes article source name")
    func buildPromptIncludesSourceName() {
        let article = Article(
            title: "Test Article",
            source: ArticleSource(id: "test", name: "The Guardian")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Source: The Guardian"))
    }

    @Test("Build prompt includes stripped description when present")
    func buildPromptIncludesDescription() {
        let article = Article(
            title: "Test Article",
            description: "This is a <strong>test</strong> description.",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: This is a test description."))
    }

    @Test("Build prompt includes truncated content when present")
    func buildPromptIncludesTruncatedContent() {
        let longContent = String(repeating: "A", count: 2000)
        let article = Article(
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test Source"),
            content: longContent
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Content:"))
        #expect(prompt.contains(String(repeating: "A", count: 1500)))
        #expect(!prompt.contains(String(repeating: "A", count: 1501)))
    }

    @Test("Build prompt with minimal article includes only title and source")
    func buildPromptWithMinimalArticle() {
        let article = Article(
            title: "Minimal Article",
            source: ArticleSource(id: "minimal", name: "Minimal Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Title: Minimal Article"))
        #expect(prompt.contains("Source: Minimal Source"))
        #expect(!prompt.contains("Description:"))
        #expect(!prompt.contains("Content:"))
    }

    @Test("Build prompt with full article includes all sections")
    func buildPromptWithFullArticle() {
        let article = Article(
            title: "Full Article Title",
            description: "A detailed description",
            source: ArticleSource(id: "full", name: "Full Source"),
            content: "The full article content here."
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Title: Full Article Title"))
        #expect(prompt.contains("Source: Full Source"))
        #expect(prompt.contains("Description: A detailed description"))
        #expect(prompt.contains("Content: The full article content here."))
    }

    @Test("Build prompt handles empty description and content")
    func buildPromptHandlesEmptyOptionalFields() {
        let article = Article(
            title: "Article with Empty Fields",
            description: "",
            source: ArticleSource(id: "empty", name: "Empty Source"),
            content: ""
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        // Empty strings should be treated as absent
        #expect(!prompt.contains("Description:"))
        #expect(!prompt.contains("Content:"))
    }

    @Test("Build prompt includes proper header")
    func buildPromptIncludesHeader() {
        let article = Article(
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.hasPrefix("Summarize this article:"))
    }

    // MARK: - HTML Stripping Tests

    @Test("HTML tags are removed from description")
    func htmlTagsRemovedFromDescription() {
        let article = Article(
            title: "Test Article",
            description: "<p>This is a <strong>test</strong> with <em>HTML</em> tags.</p>",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: This is a test with HTML tags."))
        #expect(!prompt.contains("<p>"))
        #expect(!prompt.contains("<strong>"))
        #expect(!prompt.contains("<em>"))
    }

    @Test("HTML tags are removed from content")
    func htmlTagsRemovedFromContent() {
        let article = Article(
            title: "Test Article",
            source: ArticleSource(id: "test", name: "Test Source"),
            content: "<div><h1>Header</h1><p>Paragraph content</p></div>"
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Content: Header Paragraph content"))
        #expect(!prompt.contains("<div>"))
        #expect(!prompt.contains("<h1>"))
        #expect(!prompt.contains("<p>"))
    }

    @Test("HTML entity &nbsp; is decoded to space")
    func htmlEntityNbspDecoded() {
        let article = Article(
            title: "Test Article",
            description: "Text with&nbsp;non-breaking&nbsp;spaces",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: Text with non-breaking spaces"))
        #expect(!prompt.contains("&nbsp;"))
    }

    @Test("HTML entity &amp; is decoded to &")
    func htmlEntityAmpDecoded() {
        let article = Article(
            title: "Test Article",
            description: "Apple &amp; Google partnership",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: Apple & Google partnership"))
        #expect(!prompt.contains("&amp;"))
    }

    @Test("HTML entity &lt; is decoded to <")
    func htmlEntityLtDecoded() {
        let article = Article(
            title: "Test Article",
            description: "Use &lt;script&gt; tags carefully",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: Use <script> tags carefully"))
        #expect(!prompt.contains("&lt;"))
    }

    @Test("HTML entity &gt; is decoded to >")
    func htmlEntityGtDecoded() {
        let article = Article(
            title: "Test Article",
            description: "Value is &gt; 100",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: Value is > 100"))
        #expect(!prompt.contains("&gt;"))
    }

    @Test("HTML entity &quot; is decoded to double quote")
    func htmlEntityQuotDecoded() {
        let article = Article(
            title: "Test Article",
            description: "He said &quot;Hello World&quot;",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: He said \"Hello World\""))
        #expect(!prompt.contains("&quot;"))
    }

    @Test("HTML entity &#39; is decoded to apostrophe")
    func htmlEntity39Decoded() {
        let article = Article(
            title: "Test Article",
            description: "It&#39;s a great day",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: It's a great day"))
        #expect(!prompt.contains("&#39;"))
    }

    @Test("Multiple HTML entities are decoded correctly")
    func multipleHtmlEntitiesDecoded() {
        let article = Article(
            title: "Test Article",
            description: "&lt;div&gt;Apple &amp; Google&#39;s &quot;partnership&quot;&lt;/div&gt;",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: <div>Apple & Google's \"partnership\"</div>"))
    }

    @Test("Excessive whitespace is normalized")
    func excessiveWhitespaceNormalized() {
        let article = Article(
            title: "Test Article",
            description: "Text   with    multiple     spaces",
            source: ArticleSource(id: "test", name: "Test Source")
        )

        let prompt = ArticleSummaryPromptBuilder.buildPrompt(for: article)

        #expect(prompt.contains("Description: Text with multiple spaces"))
    }

    // MARK: - System Prompt Tests

    @Test("System prompt contains summarization guidelines")
    func systemPromptContainsGuidelines() {
        let systemPrompt = ArticleSummaryPromptBuilder.systemPrompt

        #expect(systemPrompt.contains("concise news summarizer"))
        #expect(systemPrompt.contains("2-3 sentences"))
        #expect(systemPrompt.contains("key facts"))
        #expect(systemPrompt.contains("no preamble"))
    }

    @Test("System prompt instructs not to include opinions")
    func systemPromptNoOpinions() {
        let systemPrompt = ArticleSummaryPromptBuilder.systemPrompt

        #expect(systemPrompt.contains("Do not include opinions"))
    }

    @Test("System prompt instructs to start directly")
    func systemPromptStartDirectly() {
        let systemPrompt = ArticleSummaryPromptBuilder.systemPrompt

        #expect(systemPrompt.contains("Start directly"))
    }
}

// MARK: - Article Test Helpers

private extension Article {
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        source: ArticleSource,
        content: String? = nil
    ) {
        self.init(
            id: id,
            title: title,
            description: description,
            content: content,
            author: nil,
            source: source,
            url: "https://example.com/\(id)",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )
    }
}
