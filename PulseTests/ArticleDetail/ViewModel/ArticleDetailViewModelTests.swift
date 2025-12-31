import Combine
import Foundation
@testable import Pulse
import Testing

// MARK: - Test Helpers

@MainActor
private func createTestArticle(
    id: String = "test-article-1",
    content: String? = "This is the full article content with some text.",
    description: String? = "Test article description"
) -> Article {
    Article(
        id: id,
        title: "Test Article Title",
        description: description,
        content: content,
        author: "Test Author",
        source: ArticleSource(id: "test-source", name: "Test Source"),
        url: "https://example.com/article",
        imageURL: "https://example.com/image.jpg",
        publishedAt: Date(),
        category: .technology
    )
}

@MainActor
private func createTestServiceLocator() -> (ServiceLocator, MockStorageService) {
    let mockStorageService = MockStorageService()
    let serviceLocator = ServiceLocator()
    serviceLocator.register(StorageService.self, instance: mockStorageService)
    return (serviceLocator, mockStorageService)
}

private func contentString(from attributedString: AttributedString?) -> String? {
    guard let attributedString else { return nil }
    return String(attributedString.characters)
}

// MARK: - Initial State Tests

@Suite("ArticleDetailViewModel Initial State")
@MainActor
struct ArticleDetailVMInitialTests {
    @Test("Initial state has processed content")
    func initialStateHasProcessedContent() {
        let (serviceLocator, _) = createTestServiceLocator()
        let testArticle = createTestArticle()
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(sut.processedContent != nil)
        let content = contentString(from: sut.processedContent)
        #expect(content == "This is the full article content with some text.")
    }

    @Test("Initial bookmark state is false")
    func initialBookmarkStateIsFalse() {
        let (serviceLocator, _) = createTestServiceLocator()
        let testArticle = createTestArticle()
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)

        #expect(!sut.isBookmarked)
    }
}

// MARK: - HTML Processing Tests

@Suite("ArticleDetailViewModel HTML Processing")
@MainActor
struct ArticleDetailVMHTMLTests {
    @Test("HTML tags are stripped from content")
    func htmlTagsStripped() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(
            content: "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
        )
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content != nil)
        #expect(!content!.contains("<"))
        #expect(!content!.contains(">"))
    }

    @Test("HTML entity &amp; is decoded")
    func htmlEntityAmpDecoded() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "Tom &amp; Jerry")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content?.contains("Tom & Jerry") == true)
    }

    @Test("HTML entity &lt; and &gt; are decoded")
    func htmlEntityLtGtDecoded() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "5 &lt; 10 &gt; 3")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content?.contains("5 < 10 > 3") == true)
    }

    @Test("HTML entity &nbsp; is decoded to space")
    func htmlEntityNbspDecoded() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "Hello&nbsp;World")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content?.contains("Hello World") == true)
    }

    @Test("HTML entity &quot; is decoded")
    func htmlEntityQuotDecoded() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "He said &quot;Hello&quot;")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content?.contains("He said \"Hello\"") == true)
    }

    @Test("HTML entity &#39; is decoded to apostrophe")
    func htmlEntityAposDecoded() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "It&#39;s working")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content?.contains("It's working") == true)
    }
}

// MARK: - Content Processing Tests

@Suite("ArticleDetailViewModel Content Processing")
@MainActor
struct ArticleDetailVMContentTests {
    @Test("Truncation marker is removed from content")
    func truncationMarkerRemoved() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(
            content: "This is the beginning of the article... [+1234 chars]"
        )
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content != nil)
        #expect(!content!.contains("[+"))
        #expect(!content!.contains("chars]"))
    }

    @Test("Multiple whitespaces are normalized")
    func whitespaceNormalized() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "This   has    multiple     spaces")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content == "This has multiple spaces")
    }

    @Test("Nil content results in nil processed content")
    func nilContentResultsInNilProcessed() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: nil, description: "Has description")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        #expect(sut.processedContent == nil)
    }

    @Test("Empty content results in nil processed content")
    func emptyContentResultsInNilProcessed() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(content: "   ")
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        #expect(sut.processedContent == nil)
    }

    @Test("Description is processed into AttributedString")
    func descriptionIsProcessed() {
        let (serviceLocator, _) = createTestServiceLocator()
        let testArticle = createTestArticle()
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)
        #expect(sut.processedDescription != nil)
        let description = contentString(from: sut.processedDescription)
        #expect(description == "Test article description")
    }

    @Test("Nil description results in nil processed description")
    func nilDescriptionResultsInNilProcessed() {
        let (serviceLocator, _) = createTestServiceLocator()
        let article = createTestArticle(description: nil)
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        #expect(sut.processedDescription == nil)
    }

    @Test("Content with multiple sentences is formatted into paragraphs")
    func contentFormattedIntoParagraphs() {
        let (serviceLocator, _) = createTestServiceLocator()
        let multiSentenceContent = "First sentence. Second sentence. Third sentence. "
            + "Fourth sentence. Fifth sentence. Sixth sentence."
        let article = createTestArticle(content: multiSentenceContent)
        let sut = ArticleDetailViewModel(article: article, serviceLocator: serviceLocator)
        let content = contentString(from: sut.processedContent)
        #expect(content != nil)
        #expect(content!.contains("\n\n"))
    }
}

// MARK: - Bookmark & History Tests

@Suite("ArticleDetailViewModel Bookmark & History")
@MainActor
struct ArticleDetailVMBookmarkTests {
    @Test("Toggle bookmark adds article to bookmarks")
    func toggleBookmarkAddsToBookmarks() async throws {
        let (serviceLocator, mockStorageService) = createTestServiceLocator()
        let testArticle = createTestArticle()
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
        let (serviceLocator, mockStorageService) = createTestServiceLocator()
        let testArticle = createTestArticle()
        try await mockStorageService.saveArticle(testArticle)
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)
        sut.onAppear()
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(sut.isBookmarked)
        sut.toggleBookmark()
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(!sut.isBookmarked)
    }

    @Test("OnAppear saves to reading history")
    func onAppearSavesToReadingHistory() async throws {
        let (serviceLocator, mockStorageService) = createTestServiceLocator()
        let testArticle = createTestArticle()
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)
        sut.onAppear()
        try await Task.sleep(nanoseconds: 200_000_000)
        let history = try await mockStorageService.fetchReadingHistory()
        #expect(history.contains(where: { $0.id == testArticle.id }))
    }

    @Test("OnAppear checks bookmark status")
    func onAppearChecksBookmarkStatus() async throws {
        let (serviceLocator, mockStorageService) = createTestServiceLocator()
        let testArticle = createTestArticle()
        try await mockStorageService.saveArticle(testArticle)
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)
        #expect(!sut.isBookmarked)
        sut.onAppear()
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(sut.isBookmarked)
    }

    @Test("Share sets showShareSheet to true")
    func shareShowsShareSheet() {
        let (serviceLocator, _) = createTestServiceLocator()
        let testArticle = createTestArticle()
        let sut = ArticleDetailViewModel(article: testArticle, serviceLocator: serviceLocator)
        #expect(!sut.showShareSheet)
        sut.share()
        #expect(sut.showShareSheet)
    }
}
