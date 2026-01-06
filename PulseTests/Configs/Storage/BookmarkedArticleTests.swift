import Foundation
@testable import Pulse
import Testing

@Suite("BookmarkedArticle Tests")
@MainActor
struct BookmarkedArticleTests {
    let testArticle: Article

    init() {
        testArticle = Article(
            id: "test-article-id",
            title: "Test Article Title",
            description: "Test article description",
            content: "Full article content",
            author: "Test Author",
            source: ArticleSource(id: "test-source-id", name: "Test Source"),
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
            category: .technology
        )
    }

    // MARK: - Init from Article Tests

    @Test("Init from article preserves article ID")
    func initPreservesArticleId() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.articleID == testArticle.id)
    }

    @Test("Init from article preserves title")
    func initPreservesTitle() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.title == testArticle.title)
    }

    @Test("Init from article preserves description")
    func initPreservesDescription() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.articleDescription == testArticle.description)
    }

    @Test("Init from article preserves content")
    func initPreservesContent() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.content == testArticle.content)
    }

    @Test("Init from article preserves author")
    func initPreservesAuthor() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.author == testArticle.author)
    }

    @Test("Init from article preserves source name")
    func initPreservesSourceName() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.sourceName == testArticle.source.name)
    }

    @Test("Init from article preserves source ID")
    func initPreservesSourceId() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.sourceID == testArticle.source.id)
    }

    @Test("Init from article preserves URL")
    func initPreservesUrl() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.url == testArticle.url)
    }

    @Test("Init from article preserves image URL")
    func initPreservesImageUrl() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.imageURL == testArticle.imageURL)
    }

    @Test("Init from article preserves published date")
    func initPreservesPublishedAt() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.publishedAt == testArticle.publishedAt)
    }

    @Test("Init from article sets saved date to now")
    func initSetsSavedAtToNow() {
        let beforeSave = Date()
        let bookmarked = BookmarkedArticle(from: testArticle)
        let afterSave = Date()

        #expect(bookmarked.savedAt >= beforeSave)
        #expect(bookmarked.savedAt <= afterSave)
    }

    @Test("Init from article preserves category as raw value")
    func initPreservesCategoryRawValue() {
        let bookmarked = BookmarkedArticle(from: testArticle)

        #expect(bookmarked.category == testArticle.category?.rawValue)
        #expect(bookmarked.category == "technology")
    }

    // MARK: - Nil Optional Fields Tests

    @Test("Init handles nil description")
    func initHandlesNilDescription() {
        let articleWithNilDescription = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilDescription)

        #expect(bookmarked.articleDescription == nil)
    }

    @Test("Init handles nil content")
    func initHandlesNilContent() {
        let articleWithNilContent = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilContent)

        #expect(bookmarked.content == nil)
    }

    @Test("Init handles nil author")
    func initHandlesNilAuthor() {
        let articleWithNilAuthor = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilAuthor)

        #expect(bookmarked.author == nil)
    }

    @Test("Init handles nil source ID")
    func initHandlesNilSourceId() {
        let articleWithNilSourceId = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilSourceId)

        #expect(bookmarked.sourceID == nil)
    }

    @Test("Init handles nil image URL")
    func initHandlesNilImageUrl() {
        let articleWithNilImageUrl = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilImageUrl)

        #expect(bookmarked.imageURL == nil)
    }

    @Test("Init handles nil category")
    func initHandlesNilCategory() {
        let articleWithNilCategory = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilCategory)

        #expect(bookmarked.category == nil)
    }

    // MARK: - toArticle Tests

    @Test("toArticle reconstructs article correctly")
    func toArticleReconstructsCorrectly() {
        let bookmarked = BookmarkedArticle(from: testArticle)
        let reconstructed = bookmarked.toArticle()

        #expect(reconstructed.id == testArticle.id)
        #expect(reconstructed.title == testArticle.title)
        #expect(reconstructed.description == testArticle.description)
        #expect(reconstructed.content == testArticle.content)
        #expect(reconstructed.author == testArticle.author)
        #expect(reconstructed.source.id == testArticle.source.id)
        #expect(reconstructed.source.name == testArticle.source.name)
        #expect(reconstructed.url == testArticle.url)
        #expect(reconstructed.imageURL == testArticle.imageURL)
        #expect(reconstructed.publishedAt == testArticle.publishedAt)
        #expect(reconstructed.category == testArticle.category)
    }

    @Test("toArticle handles nil category")
    func toArticleHandlesNilCategory() {
        let articleWithNilCategory = Article(
            id: "test-id",
            title: "Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: nil, name: "Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: nil
        )

        let bookmarked = BookmarkedArticle(from: articleWithNilCategory)
        let reconstructed = bookmarked.toArticle()

        #expect(reconstructed.category == nil)
    }

    // MARK: - Category Roundtrip Tests

    @Test("Category roundtrip for all categories")
    func categoryRoundtripForAllCategories() {
        for category in NewsCategory.allCases {
            let article = Article(
                id: "test-\(category.rawValue)",
                title: "Title",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/\(category.rawValue)",
                imageURL: nil,
                publishedAt: Date(),
                category: category
            )

            let bookmarked = BookmarkedArticle(from: article)
            let reconstructed = bookmarked.toArticle()

            #expect(reconstructed.category == category)
        }
    }

    // MARK: - Invalid Category Test

    @Test("toArticle handles invalid category string gracefully")
    func toArticleHandlesInvalidCategoryGracefully() {
        let bookmarked = BookmarkedArticle(from: testArticle)
        bookmarked.category = "invalid-category"

        let reconstructed = bookmarked.toArticle()

        #expect(reconstructed.category == nil)
    }
}
