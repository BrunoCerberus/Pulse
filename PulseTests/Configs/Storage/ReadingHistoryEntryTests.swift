import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryEntry Tests")
@MainActor
struct ReadingHistoryEntryTests {
    // MARK: - Initialization Tests

    @Test("Init from Article preserves article ID")
    func initFromArticlePreservesArticleID() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.articleID == article.id)
    }

    @Test("Init from Article preserves title")
    func initFromArticlePreservesTitle() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.title == article.title)
    }

    @Test("Init from Article preserves description")
    func initFromArticlePreservesDescription() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.articleDescription == article.description)
    }

    @Test("Init from Article preserves source name")
    func initFromArticlePreservesSourceName() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.sourceName == article.source.name)
    }

    @Test("Init from Article preserves source ID")
    func initFromArticlePreservesSourceID() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.sourceID == article.source.id)
    }

    @Test("Init from Article preserves URL")
    func initFromArticlePreservesURL() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.url == article.url)
    }

    @Test("Init from Article preserves image URL")
    func initFromArticlePreservesImageURL() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.imageURL == article.imageURL)
    }

    @Test("Init from Article preserves published date")
    func initFromArticlePreservesPublishedDate() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.publishedAt == article.publishedAt)
    }

    @Test("Init from Article sets read date to now")
    func initFromArticleSetsReadDateToNow() {
        let beforeInit = Date()
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        let afterInit = Date()
        #expect(sut.readAt >= beforeInit)
        #expect(sut.readAt <= afterInit)
    }

    @Test("Init from Article preserves category")
    func initFromArticlePreservesCategory() {
        let article = Article.mockArticles[0]

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.category == article.category?.rawValue)
    }

    // MARK: - toArticle() Conversion Tests

    @Test("toArticle reconstructs article ID")
    func toArticleReconstructsArticleID() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.id == article.id)
    }

    @Test("toArticle reconstructs title")
    func toArticleReconstructsTitle() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.title == article.title)
    }

    @Test("toArticle reconstructs description")
    func toArticleReconstructsDescription() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.description == article.description)
    }

    @Test("toArticle reconstructs source")
    func toArticleReconstructsSource() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.source.name == article.source.name)
        #expect(reconstructed.source.id == article.source.id)
    }

    @Test("toArticle reconstructs URL")
    func toArticleReconstructsURL() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.url == article.url)
    }

    @Test("toArticle reconstructs image URL")
    func toArticleReconstructsImageURL() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.imageURL == article.imageURL)
    }

    @Test("toArticle reconstructs published date")
    func toArticleReconstructsPublishedDate() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.publishedAt == article.publishedAt)
    }

    @Test("toArticle reconstructs category")
    func toArticleReconstructsCategory() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.category == article.category)
    }

    @Test("toArticle sets content to nil")
    func toArticleSetsContentToNil() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.content == nil)
    }

    @Test("toArticle sets author to nil")
    func toArticleSetsAuthorToNil() {
        let article = Article.mockArticles[0]
        let sut = ReadingHistoryEntry(from: article)

        let reconstructed = sut.toArticle()

        #expect(reconstructed.author == nil)
    }

    // MARK: - Nil Handling Tests

    @Test("Handles article with nil description")
    func handlesArticleWithNilDescription() {
        let article = Article(
            id: "test-id",
            title: "Test Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.articleDescription == nil)
        #expect(sut.toArticle().description == nil)
    }

    @Test("Handles article with nil category")
    func handlesArticleWithNilCategory() {
        let article = Article(
            id: "test-id",
            title: "Test Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.category == nil)
        #expect(sut.toArticle().category == nil)
    }

    @Test("Handles article with nil source ID")
    func handlesArticleWithNilSourceID() {
        let article = Article(
            id: "test-id",
            title: "Test Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let sut = ReadingHistoryEntry(from: article)

        #expect(sut.sourceID == nil)
        #expect(sut.toArticle().source.id == nil)
    }
}
