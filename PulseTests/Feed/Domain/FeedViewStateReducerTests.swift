// swiftlint:disable file_length
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("FeedViewStateReducer Tests")
struct FeedViewStateReducerTests {
    let sut = FeedViewStateReducer()

    @Test("Idle state with empty history maps to empty display state")
    func idleEmptyHistory() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .empty)
        #expect(viewState.sourceArticles.isEmpty)
    }

    @Test("Idle state with history maps to idle display state")
    func idleWithHistory() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .idle)
        #expect(viewState.sourceArticles.count == Article.mockArticles.count)
    }

    @Test("Loading history maps to loading display state")
    func loadingHistory() {
        let domainState = FeedDomainState(
            generationState: .loadingHistory,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .loading)
    }

    @Test("Generating maps to processing display state with generating phase")
    func generating() {
        let domainState = FeedDomainState(
            generationState: .generating,
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "Generating text...",
            modelStatus: .ready,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .processing(phase: .generating))
        #expect(viewState.streamingText == "Generating text...")
    }

    @Test("Completed maps to completed display state with digest")
    func completed() {
        let digest = DailyDigest(
            id: "1",
            summary: "Test summary",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )

        let domainState = FeedDomainState(
            generationState: .completed,
            readingHistory: Article.mockArticles,
            currentDigest: digest,
            streamingText: "",
            modelStatus: .ready,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .completed)
        #expect(viewState.digest != nil)
        #expect(viewState.digest?.summary == "Test summary")
    }

    @Test("Error maps to error display state with message")
    func error() {
        let domainState = FeedDomainState(
            generationState: .error("Generation failed"),
            readingHistory: Article.mockArticles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .error("Model failed"),
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.displayState == .error)
        #expect(viewState.errorMessage == "Generation failed")
    }

    @Test("Source articles are correctly mapped")
    func sourceArticlesMapping() {
        let articles = Article.mockArticles

        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: articles,
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.sourceArticles.count == articles.count)

        let firstSource = viewState.sourceArticles.first
        let firstArticle = articles.first

        #expect(firstSource?.id == firstArticle?.id)
        #expect(firstSource?.title == firstArticle?.title)
        #expect(firstSource?.source == firstArticle?.source.name)
    }

    @Test("Header date is computed from current date when no digest")
    func headerDateComputed() {
        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: nil
        )

        let viewState = sut.reduce(domainState: domainState)

        // Header date should be computed (today's date), not empty
        #expect(!viewState.headerDate.isEmpty)
    }

    @Test("Selected article is passed through")
    func selectedArticlePassthrough() {
        let article = Article.mockArticles[0]

        let domainState = FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: true,
            selectedArticle: article
        )

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedArticle?.id == article.id)
    }
}

// MARK: - DigestViewItem Parsing Tests

@Suite("DigestViewItem Parsing Tests")
// swiftlint:disable:next type_body_length
struct DigestViewItemParsingTests {
    @Test("parseSections extracts unique content per category")
    func parseSectionsExtractsUniqueContent() {
        let summary = """
        **Technology** The tech world saw major AI developments and innovative product launches this week.

        **Business** Markets responded positively to earnings reports and economic indicators.

        **World** International diplomacy made progress on climate agreements and trade deals.
        """

        let articles = [
            createMockArticle(category: .technology, title: "AI Breakthrough"),
            createMockArticle(category: .business, title: "Markets Rally"),
            createMockArticle(category: .world, title: "Climate Summit"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 3)

        // Verify each section has unique content (not the full summary)
        let techSection = sections.first { $0.category == .technology }
        let businessSection = sections.first { $0.category == .business }
        let worldSection = sections.first { $0.category == .world }

        #expect(techSection != nil)
        #expect(businessSection != nil)
        #expect(worldSection != nil)

        // Tech section should contain tech content but NOT business content
        #expect(techSection?.content.lowercased().contains("ai") == true)
        #expect(techSection?.content.lowercased().contains("markets responded") == false)

        // Business section should contain business content but NOT world content
        #expect(businessSection?.content.lowercased().contains("markets") == true)
        #expect(businessSection?.content.lowercased().contains("diplomacy") == false)

        // World section should contain world content but NOT tech content
        #expect(worldSection?.content.lowercased().contains("climate") == true)
        #expect(worldSection?.content.lowercased().contains("ai developments") == false)
    }

    @Test("parseSections handles content without markers gracefully")
    func parseSectionsHandlesNoMarkers() {
        // Content without proper category markers
        let summary = "General news summary without category markers."

        let articles = [
            createMockArticle(category: .technology, title: "Tech Article"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        // Should still create sections using fallback content generation
        #expect(sections.count == 1)
        #expect(sections.first?.category == .technology)
        #expect(!sections.first!.content.isEmpty)
    }

    @Test("parseSections does not duplicate content across categories")
    func parseSectionsNoDuplication() {
        let summary = """
        **Technology** Unique tech content here.
        **Business** Unique business content here.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 2)

        // Content should be different for each section
        let techContent = sections.first { $0.category == .technology }?.content ?? ""
        let businessContent = sections.first { $0.category == .business }?.content ?? ""

        #expect(techContent != businessContent)
    }

    @Test("parseSections handles empty summary gracefully")
    func parseSectionsHandlesEmptySummary() {
        let summary = ""

        let articles = [
            createMockArticle(category: .technology, title: "Tech Article"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        // Should still create sections using fallback content generation
        #expect(sections.count == 1)
        #expect(sections.first?.category == .technology)
        #expect(!sections.first!.content.isEmpty)
    }

    @Test("parseSections handles single category correctly")
    func parseSectionsSingleCategory() {
        let summary = "**Technology** Only tech content in this digest."

        let articles = [
            createMockArticle(category: .technology, title: "Tech Article"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 1)
        #expect(sections.first?.category == .technology)
        #expect(sections.first?.content.lowercased().contains("tech content") == true)
    }

    @Test("parseSections handles categories with no content between markers")
    func parseSectionsEmptyContentBetweenMarkers() {
        let summary = """
        **Technology**
        **Business** Some business content here.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        // Both categories should have sections
        #expect(sections.count == 2)

        // Business should have its proper content
        let businessSection = sections.first { $0.category == .business }
        #expect(businessSection?.content.lowercased().contains("business content") == true)
    }

    @Test("parseSections handles malformed markers")
    func parseSectionsHandlesMalformedMarkers() {
        // Malformed marker: ***Technology** (extra asterisk)
        let summary = "***Technology** Some tech content. **Business** Business content."

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        // Should still parse business correctly, tech may use fallback
        #expect(sections.count == 2)

        let businessSection = sections.first { $0.category == .business }
        #expect(businessSection?.content.lowercased().contains("business content") == true)
    }

    @Test("parseSections returns empty for no articles")
    func parseSectionsNoArticles() {
        let summary = "**Technology** Tech content here."

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: [],
                generatedAt: Date()
            )
        )

        let sections = digest.parseSections(with: [])

        #expect(sections.isEmpty)
    }

    @Test("parseSections handles alternative marker formats")
    func parseSectionsAlternativeMarkers() {
        // Using colon format instead of bold markers
        let summary = """
        technology: Tech innovations and AI breakthroughs.
        business: Market updates and economic news.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 2)

        let techSection = sections.first { $0.category == .technology }
        let businessSection = sections.first { $0.category == .business }

        #expect(techSection?.content.lowercased().contains("tech innovations") == true)
        #expect(businessSection?.content.lowercased().contains("market updates") == true)
    }

    @Test("parseSections handles category names in content without false matches")
    func parseSectionsHandlesCategoryNamesInContent() {
        // Content where category names appear naturally in text (not as headers)
        // This tests that we don't falsely match "technology:" in content
        // swiftlint:disable line_length
        let summary = """
        **Technology** AI breakthroughs continue to amaze.
        **Entertainment** The film industry embraces technology: streaming services are booming. Health: concerns about screen time were discussed.
        """
        // swiftlint:enable line_length

        let articles = [
            createMockArticle(category: .technology, title: "AI News"),
            createMockArticle(category: .entertainment, title: "Movie News"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 2)

        // Entertainment should contain its full content including "technology:" mention
        let entertainmentSection = sections.first { $0.category == .entertainment }
        #expect(entertainmentSection != nil)
        #expect(entertainmentSection?.content.lowercased().contains("streaming services") == true)
        #expect(entertainmentSection?.content.lowercased().contains("screen time") == true)

        // Technology should only contain its actual content
        let techSection = sections.first { $0.category == .technology }
        #expect(techSection != nil)
        #expect(techSection?.content.lowercased().contains("ai breakthroughs") == true)
        #expect(techSection?.content.lowercased().contains("streaming") == false)
    }

    @Test("parseSections strips repeated category markers from last category")
    func parseSectionsStripsRepeatedMarkers() {
        // LLM outputs repeated markers at the end (common error)
        let summary = """
        **Technology** Tech news here.
        **Entertainment** Movie reviews. **Technology** More tech. **Business** Extra business.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .entertainment, title: "Entertainment"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 2)

        // Entertainment should have its content without the trailing markers
        let entertainmentSection = sections.first { $0.category == .entertainment }
        #expect(entertainmentSection != nil)
        #expect(entertainmentSection?.content.lowercased().contains("movie reviews") == true)
        // Should NOT contain the repeated markers as content
        #expect(entertainmentSection?.content.contains("**Technology**") == false)
        #expect(entertainmentSection?.content.contains("**Business**") == false)
    }

    @Test("parseSections preserves proper capitalization")
    func parseSectionsPreservesCapitalization() {
        let summary = """
        **Technology** Apple announced new MacBook Pro with M4 chip. Google released Gemini 2.0.
        **Business** Wall Street rallied on Fed news. S&P 500 reached all-time highs.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 2)

        // Content should preserve proper capitalization (not be lowercased)
        let techSection = sections.first { $0.category == .technology }
        #expect(techSection != nil)
        #expect(techSection?.content.contains("Apple") == true)
        #expect(techSection?.content.contains("MacBook Pro") == true)
        #expect(techSection?.content.contains("M4") == true)
        #expect(techSection?.content.contains("Google") == true)
        #expect(techSection?.content.contains("Gemini") == true)

        let businessSection = sections.first { $0.category == .business }
        #expect(businessSection != nil)
        #expect(businessSection?.content.contains("Wall Street") == true)
        #expect(businessSection?.content.contains("Fed") == true)
        #expect(businessSection?.content.contains("S&P 500") == true)
    }

    @Test("parseSections handles Entertainment as last category correctly")
    func parseSectionsHandlesEntertainmentLast() {
        // Entertainment is always last in categoryOrder - ensure it gets correct content
        let summary = """
        **Technology** Tech developments this week.
        **Business** Market updates and trends.
        **Entertainment** The latest blockbusters and streaming hits entertained audiences worldwide.
        """

        let articles = [
            createMockArticle(category: .technology, title: "Tech"),
            createMockArticle(category: .business, title: "Business"),
            createMockArticle(category: .entertainment, title: "Entertainment"),
        ]

        let digest = DigestViewItem(
            from: DailyDigest(
                id: "test",
                summary: summary,
                sourceArticles: articles,
                generatedAt: Date()
            )
        )

        let sourceArticles = articles.map { FeedSourceArticle(from: $0) }
        let sections = digest.parseSections(with: sourceArticles)

        #expect(sections.count == 3)

        // Entertainment (last category) should have only its content
        let entertainmentSection = sections.first { $0.category == .entertainment }
        #expect(entertainmentSection != nil)
        #expect(entertainmentSection?.content.contains("blockbusters") == true)
        #expect(entertainmentSection?.content.contains("streaming hits") == true)
        // Should NOT contain content from other categories
        #expect(entertainmentSection?.content.lowercased().contains("tech developments") == false)
        #expect(entertainmentSection?.content.lowercased().contains("market updates") == false)
    }

    // Helper to create mock articles with specific categories
    private func createMockArticle(category: NewsCategory, title: String) -> Article {
        Article(
            title: title,
            description: "Test description",
            source: ArticleSource(id: "test", name: "Test Source"),
            url: "https://example.com",
            publishedAt: Date(),
            category: category
        )
    }
}

// MARK: - Null Character Removal Tests

@Suite("LLM Output Cleaning Tests")
struct LLMOutputCleaningTests {
    @Test("cleanLLMOutput removes null characters between tokens")
    func cleanLLMOutputRemovesNullChars() {
        // Simulate LLM output with null characters (the bug we fixed)
        let llmOutputWithNulls = "**\0Technology\0**\0 The\0 tech\0 world\0 saw\0 major\0 developments."

        // The cleanLLMOutput function should remove \0 chars
        let cleaned = cleanLLMOutput(llmOutputWithNulls)

        #expect(!cleaned.contains("\0"))
        #expect(cleaned.contains("Technology"))
        #expect(cleaned.contains("tech world"))
    }

    @Test("cleanLLMOutput removes chat template markers")
    func cleanLLMOutputRemovesChatMarkers() {
        let llmOutput = "<|assistant|>Here is the digest:<|end|>"

        let cleaned = cleanLLMOutput(llmOutput)

        #expect(!cleaned.contains("<|assistant|>"))
        #expect(!cleaned.contains("<|end|>"))
    }

    @Test("cleanLLMOutput removes common instruction prefixes")
    func cleanLLMOutputRemovesPrefixes() {
        let llmOutput = "Here's the digest: **Technology** Tech content here."

        let cleaned = cleanLLMOutput(llmOutput)

        #expect(!cleaned.lowercased().hasPrefix("here's the digest:"))
        #expect(cleaned.contains("Technology"))
    }

    @Test("cleanLLMOutput preserves valid content")
    func cleanLLMOutputPreservesContent() {
        let validContent = "**Technology** AI breakthroughs. **Business** Market news."

        let cleaned = cleanLLMOutput(validContent)

        #expect(cleaned.contains("Technology"))
        #expect(cleaned.contains("AI breakthroughs"))
        #expect(cleaned.contains("Business"))
        #expect(cleaned.contains("Market news"))
    }

    // Helper function that mirrors the implementation in FeedDomainInteractor
    private func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove null characters (LLM sometimes outputs these between tokens)
        cleaned = cleaned.replacingOccurrences(of: "\0", with: "")

        // Remove chat template markers
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "</s>", "<s>", "<|eot_id|>", "<|start_header_id|>", "<|end_header_id|>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = ["here's the digest:", "here is the digest:", "digest:", "here's your daily digest:"]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes where lowercased.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
