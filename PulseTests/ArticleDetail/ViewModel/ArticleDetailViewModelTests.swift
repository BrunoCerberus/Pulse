import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailViewModel Tests")
@MainActor
struct ArticleDetailViewModelTests {
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let testArticle: Article

    init() {
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StorageService.self, instance: mockStorageService)

        testArticle = Article(
            id: "test-article-1",
            title: "Test Article Title",
            description: "Test article description",
            content: "This is the full article content with some text.",
            author: "Test Author",
            source: ArticleSource(id: "test-source", name: "Test Source"),
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Date(),
            category: .technology
        )
    }

    // MARK: - Helper

    private func contentString(from attributedString: AttributedString?) -> String? {
        guard let attributedString else { return nil }
        return String(attributedString.characters)
    }

    // MARK: - Initial State Tests

    @Test("Initial state has processed content")
    func initialStateHasProcessedContent() {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(sut.processedContent != nil)
        #expect(contentString(from: sut.processedContent) == "This is the full article content with some text.")
    }

    @Test("Initial bookmark state is false")
    func initialBookmarkStateIsFalse() {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(!sut.isBookmarked)
    }

    // MARK: - HTML Stripping Tests

    @Test("HTML tags are stripped from content")
    func htmlTagsStripped() {
        let articleWithHTML = Article(
            id: "html-article",
            title: "HTML Article",
            description: nil,
            content: "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithHTML, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content != nil)
        #expect(!content!.contains("<"))
        #expect(!content!.contains(">"))
    }

    @Test("HTML entity &amp; is decoded")
    func htmlEntityAmpDecoded() {
        let articleWithEntity = Article(
            id: "entity-article",
            title: "Entity Article",
            description: nil,
            content: "Tom &amp; Jerry",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEntity, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content?.contains("Tom & Jerry") == true)
    }

    @Test("HTML entity &lt; and &gt; are decoded")
    func htmlEntityLtGtDecoded() {
        let articleWithEntity = Article(
            id: "entity-article",
            title: "Entity Article",
            description: nil,
            content: "5 &lt; 10 &gt; 3",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEntity, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content?.contains("5 < 10 > 3") == true)
    }

    @Test("HTML entity &nbsp; is decoded to space")
    func htmlEntityNbspDecoded() {
        let articleWithEntity = Article(
            id: "entity-article",
            title: "Entity Article",
            description: nil,
            content: "Hello&nbsp;World",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEntity, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content?.contains("Hello World") == true)
    }

    @Test("HTML entity &quot; is decoded")
    func htmlEntityQuotDecoded() {
        let articleWithEntity = Article(
            id: "entity-article",
            title: "Entity Article",
            description: nil,
            content: "He said &quot;Hello&quot;",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEntity, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content?.contains("He said \"Hello\"") == true)
    }

    @Test("HTML entity &#39; is decoded to apostrophe")
    func htmlEntityAposDecoded() {
        let articleWithEntity = Article(
            id: "entity-article",
            title: "Entity Article",
            description: nil,
            content: "It&#39;s working",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEntity, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content?.contains("It's working") == true)
    }

    // MARK: - Truncation Marker Tests

    @Test("Truncation marker is removed from content")
    func truncationMarkerRemoved() {
        let articleWithTruncation = Article(
            id: "truncated-article",
            title: "Truncated Article",
            description: nil,
            content: "This is the beginning of the article... [+1234 chars]",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithTruncation, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content != nil)
        #expect(!content!.contains("[+"))
        #expect(!content!.contains("chars]"))
    }

    // MARK: - Whitespace Normalization Tests

    @Test("Multiple whitespaces are normalized")
    func whitespaceNormalized() {
        let articleWithWhitespace = Article(
            id: "whitespace-article",
            title: "Whitespace Article",
            description: nil,
            content: "This   has    multiple     spaces",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithWhitespace, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content == "This has multiple spaces")
    }

    // MARK: - Nil Content Tests

    @Test("Nil content results in nil processed content")
    func nilContentResultsInNilProcessed() {
        let articleWithNilContent = Article(
            id: "nil-content-article",
            title: "No Content Article",
            description: "Has description but no content",
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithNilContent, serviceLocator: serviceLocator)

        #expect(sut.processedContent == nil)
    }

    @Test("Empty content results in nil processed content")
    func emptyContentResultsInNilProcessed() {
        let articleWithEmptyContent = Article(
            id: "empty-content-article",
            title: "Empty Content Article",
            description: nil,
            content: "   ",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithEmptyContent, serviceLocator: serviceLocator)

        #expect(sut.processedContent == nil)
    }

    // MARK: - Bookmark Tests

    @Test("Toggle bookmark adds article to bookmarks")
    func toggleBookmarkAddsToBookmarks() async throws {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(!sut.isBookmarked)

        sut.toggleBookmark()

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.isBookmarked)
        let isBookmarked = await mockStorageService.isBookmarked(testArticle.id)
        #expect(isBookmarked)
    }

    @Test("Toggle bookmark removes article from bookmarks when bookmarked")
    func toggleBookmarkRemovesFromBookmarks() async throws {
        // Pre-bookmark the article
        try await mockStorageService.saveArticle(testArticle)

        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        // Need to call onAppear to check bookmark status
        sut.onAppear()
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.isBookmarked)

        sut.toggleBookmark()

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!sut.isBookmarked)
    }

    // MARK: - Reading History Tests

    @Test("OnAppear saves to reading history")
    func onAppearSavesToReadingHistory() async throws {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        sut.onAppear()

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == testArticle.id }))
    }

    @Test("OnAppear checks bookmark status")
    func onAppearChecksBookmarkStatus() async throws {
        // Pre-bookmark the article
        try await mockStorageService.saveArticle(testArticle)

        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(!sut.isBookmarked) // Initially false

        sut.onAppear()

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.isBookmarked) // Should be true after checking
    }

    // MARK: - Share Tests

    @Test("Share sets showShareSheet to true")
    func shareShowsShareSheet() {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(!sut.showShareSheet)

        sut.share()

        #expect(sut.showShareSheet)
    }

    // MARK: - Description Processing Tests

    @Test("Description is processed into AttributedString")
    func descriptionIsProcessed() {
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(sut.processedDescription != nil)
        let description = contentString(from: sut.processedDescription)
        #expect(description == "Test article description")
    }

    @Test("Nil description results in nil processed description")
    func nilDescriptionResultsInNilProcessed() {
        let articleWithNilDescription = Article(
            id: "nil-desc-article",
            title: "No Description Article",
            description: nil,
            content: "Some content",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithNilDescription, serviceLocator: serviceLocator)

        #expect(sut.processedDescription == nil)
    }

    // MARK: - Paragraph Formatting Tests

    @Test("Content with multiple sentences is formatted into paragraphs")
    func contentFormattedIntoParagraphs() {
        let articleWithSentences = Article(
            id: "sentences-article",
            title: "Multi-sentence Article",
            description: nil,
            content: "First sentence. Second sentence. Third sentence. Fourth sentence. Fifth sentence. Sixth sentence.",
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ArticleDetailViewModel(article: articleWithSentences, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)

        #expect(content != nil)
        #expect(content!.contains("\n\n"))
    }
}
