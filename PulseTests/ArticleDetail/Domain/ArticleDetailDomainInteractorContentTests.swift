import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Content Processing Tests

extension ArticleDetailDomainInteractorTests {
    @Test("Content processing completes with processed content")
    func contentProcessingCompletes() async {
        let articleWithContent = Article(
            id: "test-1",
            title: "Test Article",
            description: "First sentence. Second sentence. Third sentence.",
            content: "<p>Paragraph one. Sentence two. Sentence three.</p>",
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithContent)

        // Wait for content processing to complete
        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            !sut.currentState.isProcessingContent &&
                sut.currentState.processedContent != nil &&
                sut.currentState.processedDescription != nil
        }
        #expect(success)
    }

    @Test("Content processing handles nil content")
    func contentProcessingHandlesNil() async {
        let articleWithoutContent = Article(
            id: "test-2",
            title: "Test Article",
            description: nil,
            content: nil,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithoutContent)

        // Wait for content processing to complete (should finish quickly with nil values)
        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            !sut.currentState.isProcessingContent
        }
        #expect(success)
        #expect(sut.currentState.processedContent == nil)
        #expect(sut.currentState.processedDescription == nil)
    }

    @Test("bookmarkStatusLoaded action updates state")
    func bookmarkStatusLoaded() {
        let sut = createSUT()

        sut.dispatch(action: .bookmarkStatusLoaded(true))

        #expect(sut.currentState.isBookmarked == true)

        sut.dispatch(action: .bookmarkStatusLoaded(false))

        #expect(sut.currentState.isBookmarked == false)
    }

    @Test("contentProcessingCompleted action updates state")
    func contentProcessingCompletedAction() {
        let sut = createSUT()

        let testContent = AttributedString("Test content")
        let testDescription = AttributedString("Test description")

        sut.dispatch(action: .contentProcessingCompleted(
            content: testContent,
            description: testDescription
        ))

        #expect(sut.currentState.isProcessingContent == false)
        #expect(sut.currentState.processedContent != nil)
        #expect(sut.currentState.processedDescription != nil)
    }

    // MARK: - Content Filter Tests (BUG #1)

    @Test("Content containing only known error phrases produces nil processed content")
    func contentFilterStripsAllNoisePhrases() async {
        // Content that is purely a Guardian anti-adblock/scraper error message
        let errorOnlyContent =
            "A required part of this site couldn't load. "
                + "This may be due to a browser extension, network issues, or browser settings. "
                + "Please check your connection, disable any ad blockers, or try a different browser."

        let articleWithErrorContent = Article(
            id: "filter-test-1",
            title: "Error Content Article",
            description: nil,
            content: errorOnlyContent,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithErrorContent)

        // Wait for content processing to finish
        let finished = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            !sut.currentState.isProcessingContent
        }
        #expect(finished)

        // All-noise content should produce nil processedContent (nothing useful to show)
        #expect(sut.currentState.processedContent == nil)
    }

    @Test("Valid article content passes through content filter unchanged")
    func contentFilterPreservesRealContent() async {
        let realContent =
            "<p>This is a genuine news article paragraph with substantive content about world events. "
                + "It contains multiple sentences and real information that readers would want to read.</p>"

        let articleWithRealContent = Article(
            id: "filter-test-2",
            title: "Real Content Article",
            description: nil,
            content: realContent,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithRealContent)

        let finished = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            !sut.currentState.isProcessingContent
        }
        #expect(finished)

        // Real content should pass through and produce a non-nil processedContent
        #expect(sut.currentState.processedContent != nil)
    }

    @Test("Content filter strips JavaScript error phrase from mixed content")
    func contentFilterStripsJsErrorFromMixedContent() async {
        // Content that starts with a JS error phrase but has real content after
        let mixedContent =
            "You need to enable JavaScript to run this app\n\n"
                + "This is the real article content that should be preserved after the error phrase is stripped."

        let articleWithMixedContent = Article(
            id: "filter-test-3",
            title: "Mixed Content Article",
            description: nil,
            content: mixedContent,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithMixedContent)

        let finished = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            !sut.currentState.isProcessingContent
        }
        #expect(finished)

        // Real portion of content should survive the filter
        #expect(sut.currentState.processedContent != nil)
        // Error phrase should not appear in the processed output
        if let processedContent = sut.currentState.processedContent {
            let contentString = String(processedContent.characters)
            #expect(!contentString.contains("You need to enable JavaScript"))
        }
    }
}
