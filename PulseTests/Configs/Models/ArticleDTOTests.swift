import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDTO Tests")
struct ArticleDTOTests {
    // MARK: - Date Parsing Tests

    @Test("ISO8601 date with fractional seconds parses correctly")
    func iso8601WithFractionalSeconds() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2024-01-15T10:30:00.000Z",
            content: "Content"
        )

        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }

    @Test("ISO8601 date without fractional seconds parses correctly")
    func iso8601WithoutFractionalSeconds() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2024-01-15T10:30:00Z",
            content: "Content"
        )

        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }

    @Test("Invalid date returns nil article")
    func invalidDateReturnsNil() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "invalid-date",
            content: "Content"
        )

        let article = dto.toArticle()

        #expect(article == nil)
    }

    @Test("Empty date string returns nil article")
    func emptyDateReturnsNil() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "",
            content: "Content"
        )

        let article = dto.toArticle()

        #expect(article == nil)
    }

    // MARK: - URL as ID Tests

    @Test("URL becomes article ID")
    func urlBecomesArticleId() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/unique-article-url",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: "Content"
        )

        let article = dto.toArticle()

        #expect(article?.id == "https://example.com/unique-article-url")
    }

    // MARK: - Optional Field Tests

    @Test("Optional author is preserved")
    func optionalAuthorPreserved() {
        let dtoWithAuthor = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "John Doe",
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let dtoWithoutAuthor = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article2",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let articleWithAuthor = dtoWithAuthor.toArticle()
        let articleWithoutAuthor = dtoWithoutAuthor.toArticle()

        #expect(articleWithAuthor?.author == "John Doe")
        #expect(articleWithoutAuthor?.author == nil)
    }

    @Test("Optional description is preserved")
    func optionalDescriptionPreserved() {
        let dtoWithDescription = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: "This is a description",
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let article = dtoWithDescription.toArticle()

        #expect(article?.description == "This is a description")
    }

    @Test("Optional content is preserved")
    func optionalContentPreserved() {
        let dtoWithContent = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: "Full article content"
        )

        let article = dtoWithContent.toArticle()

        #expect(article?.content == "Full article content")
    }

    @Test("Optional image URL is preserved")
    func optionalImageUrlPreserved() {
        let dtoWithImage = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let dtoWithoutImage = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article2",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let articleWithImage = dtoWithImage.toArticle()
        let articleWithoutImage = dtoWithoutImage.toArticle()

        #expect(articleWithImage?.imageURL == "https://example.com/image.jpg")
        #expect(articleWithoutImage?.imageURL == nil)
    }

    // MARK: - Category Tests

    @Test("Category is passed through correctly")
    func categoryPassedThrough() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let articleWithCategory = dto.toArticle(category: .technology)
        let articleWithoutCategory = dto.toArticle()

        #expect(articleWithCategory?.category == .technology)
        #expect(articleWithoutCategory?.category == nil)
    }

    @Test("All categories can be assigned")
    func allCategoriesCanBeAssigned() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        for category in NewsCategory.allCases {
            let article = dto.toArticle(category: category)
            #expect(article?.category == category)
        }
    }

    // MARK: - Source Tests

    @Test("Source is transformed correctly")
    func sourceTransformedCorrectly() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "bbc-news", name: "BBC News"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let article = dto.toArticle()

        #expect(article?.source.id == "bbc-news")
        #expect(article?.source.name == "BBC News")
    }

    @Test("Source with nil ID is handled")
    func sourceWithNilIdHandled() {
        let dto = ArticleDTO(
            source: SourceDTO(id: nil, name: "Unknown Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let article = dto.toArticle()

        #expect(article?.source.id == nil)
        #expect(article?.source.name == "Unknown Source")
    }

    // MARK: - Full Transformation Test

    @Test("Full DTO transformation preserves all fields")
    func fullDtoTransformationPreservesAllFields() {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test-source", name: "Test Source Name"),
            author: "Test Author",
            title: "Test Article Title",
            description: "Test article description",
            url: "https://example.com/test-article",
            urlToImage: "https://example.com/test-image.jpg",
            publishedAt: "2024-06-15T14:30:00.123Z",
            content: "Full article content here"
        )

        let article = dto.toArticle(category: .science)

        #expect(article != nil)
        #expect(article?.id == "https://example.com/test-article")
        #expect(article?.title == "Test Article Title")
        #expect(article?.description == "Test article description")
        #expect(article?.content == "Full article content here")
        #expect(article?.author == "Test Author")
        #expect(article?.source.id == "test-source")
        #expect(article?.source.name == "Test Source Name")
        #expect(article?.url == "https://example.com/test-article")
        #expect(article?.imageURL == "https://example.com/test-image.jpg")
        #expect(article?.category == .science)
    }
}
