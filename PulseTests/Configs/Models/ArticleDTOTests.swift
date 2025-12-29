import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDTO Tests")
struct ArticleDTOTests {
    // MARK: - Date Parsing Tests (Consolidated)

    @Test(
        "Date parsing handles various ISO8601 formats",
        arguments: [
            ("2024-01-15T10:30:00.000Z", true), // With fractional seconds
            ("2024-01-15T10:30:00Z", true), // Without fractional seconds
            ("invalid-date", false), // Invalid format
            ("", false), // Empty string
        ]
    )
    func dateParsingHandlesVariousFormats(dateString: String, shouldSucceed: Bool) {
        let dto = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "Author",
            title: "Test Title",
            description: "Description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: dateString,
            content: "Content"
        )

        let article = dto.toArticle()

        if shouldSucceed {
            #expect(article != nil)
            #expect(article?.publishedAt != nil)
        } else {
            #expect(article == nil)
        }
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

    // MARK: - Optional Field Tests (Consolidated)

    @Test("All optional fields are preserved correctly")
    func optionalFieldsArePreserved() {
        // Test with all optional fields present
        let dtoWithAllFields = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: "John Doe",
            title: "Test Title",
            description: "This is a description",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2024-01-15T10:30:00Z",
            content: "Full article content"
        )

        // Test without optional fields
        let dtoWithoutOptionalFields = ArticleDTO(
            source: SourceDTO(id: "test", name: "Test Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article2",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let articleWithFields = dtoWithAllFields.toArticle()
        let articleWithoutFields = dtoWithoutOptionalFields.toArticle()

        // Verify fields are preserved when present
        #expect(articleWithFields?.author == "John Doe")
        #expect(articleWithFields?.description == "This is a description")
        #expect(articleWithFields?.content == "Full article content")
        #expect(articleWithFields?.imageURL == "https://example.com/image.jpg")

        // Verify nil when absent
        #expect(articleWithoutFields?.author == nil)
        #expect(articleWithoutFields?.description == nil)
        #expect(articleWithoutFields?.content == nil)
        #expect(articleWithoutFields?.imageURL == nil)
    }

    // MARK: - Category Tests (Consolidated)

    @Test("Category is passed through correctly for all categories")
    func categoryPassedThroughForAllCategories() {
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

        // Test without category
        let articleWithoutCategory = dto.toArticle()
        #expect(articleWithoutCategory?.category == nil)

        // Test with all categories
        for category in NewsCategory.allCases {
            let article = dto.toArticle(category: category)
            #expect(article?.category == category)
        }
    }

    // MARK: - Source Tests (Consolidated)

    @Test("Source is transformed correctly including nil ID handling")
    func sourceTransformedCorrectly() {
        let dtoWithSourceId = ArticleDTO(
            source: SourceDTO(id: "bbc-news", name: "BBC News"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article1",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let dtoWithNilSourceId = ArticleDTO(
            source: SourceDTO(id: nil, name: "Unknown Source"),
            author: nil,
            title: "Test Title",
            description: nil,
            url: "https://example.com/article2",
            urlToImage: nil,
            publishedAt: "2024-01-15T10:30:00Z",
            content: nil
        )

        let articleWithSourceId = dtoWithSourceId.toArticle()
        let articleWithNilSourceId = dtoWithNilSourceId.toArticle()

        #expect(articleWithSourceId?.source.id == "bbc-news")
        #expect(articleWithSourceId?.source.name == "BBC News")
        #expect(articleWithNilSourceId?.source.id == nil)
        #expect(articleWithNilSourceId?.source.name == "Unknown Source")
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
