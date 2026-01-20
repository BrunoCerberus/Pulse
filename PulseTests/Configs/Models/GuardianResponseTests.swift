import Foundation
@testable import Pulse
import Testing

@Suite("GuardianResponse Initialization Tests")
struct GuardianResponseInitializationTests {
    @Test("Can create GuardianResponse")
    func guardianResponseInitialization() {
        let content = GuardianResponseContent(
            status: "ok",
            total: 100,
            startIndex: 1,
            pageSize: 10,
            currentPage: 1,
            pages: 10,
            results: []
        )
        let response = GuardianResponse(response: content)

        #expect(response.response.status == "ok")
        #expect(response.response.total == 100)
    }

    @Test("Can create GuardianResponseContent")
    func guardianResponseContentInitialization() {
        let content = GuardianResponseContent(
            status: "ok",
            total: 50,
            startIndex: 1,
            pageSize: 20,
            currentPage: 1,
            pages: 3,
            results: []
        )

        #expect(content.status == "ok")
        #expect(content.total == 50)
        #expect(content.pageSize == 20)
        #expect(content.currentPage == 1)
        #expect(content.pages == 3)
    }
}

@Suite("GuardianArticleDTO Tests")
struct GuardianArticleDTOTests {
    @Test("Can create GuardianArticleDTO")
    func guardianArticleDTOInitialization() {
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: nil
        )

        #expect(dto.id == "article-1")
        #expect(dto.type == "article")
        #expect(dto.webTitle == "Test Article")
        #expect(dto.sectionId == "world")
    }

    @Test("Can create GuardianArticleDTO with fields")
    func guardianArticleDTOWithFields() {
        let fields = GuardianFieldsDTO(
            thumbnail: "https://example.com/image.jpg",
            trailText: "Trail text",
            body: "Full content",
            byline: "John Doe"
        )
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: fields
        )

        #expect(dto.fields?.thumbnail == "https://example.com/image.jpg")
        #expect(dto.fields?.trailText == "Trail text")
        #expect(dto.fields?.body == "Full content")
        #expect(dto.fields?.byline == "John Doe")
    }
}

@Suite("GuardianArticleDTO Date Parsing Tests")
struct GuardianArticleDTODateParsingTests {
    @Test("Can parse ISO8601 date with fractional seconds")
    func parseDateWithFractionalSeconds() {
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:45.123Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: nil
        )

        let article = dto.toArticle()
        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }

    @Test("Can parse ISO8601 date without fractional seconds")
    func parseDateWithoutFractionalSeconds() {
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: nil
        )

        let article = dto.toArticle()
        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }

    @Test("Returns nil for invalid date")
    func parseInvalidDate() {
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "invalid-date",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: nil
        )

        let article = dto.toArticle()
        #expect(article == nil)
    }
}

@Suite("GuardianArticleDTO to Article Conversion Tests")
struct GuardianArticleDTOConversionTests {
    @Test("Can convert DTO to Article with category")
    func convertToArticleWithCategory() {
        let fields = GuardianFieldsDTO(
            thumbnail: "https://example.com/image.jpg",
            trailText: "Trail text",
            body: "Full content",
            byline: "John Doe"
        )
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Breaking News",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: fields
        )

        let article = dto.toArticle(category: .world)

        #expect(article != nil)
        #expect(article?.id == "article-1")
        #expect(article?.title == "Breaking News")
        #expect(article?.description == "Trail text")
        #expect(article?.content == "Full content")
        #expect(article?.author == "John Doe")
        #expect(article?.imageURL == "https://example.com/image.jpg")
        #expect(article?.category == .world)
    }

    @Test("Can convert DTO to Article without category")
    func convertToArticleWithoutCategory() {
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: nil
        )

        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.id == "article-1")
        #expect(article?.title == "Test Article")
    }

    @Test("Converts null optional fields properly")
    func convertNullFields() {
        let fields = GuardianFieldsDTO(
            thumbnail: nil,
            trailText: nil,
            body: nil,
            byline: nil
        )
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: fields
        )

        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.description == nil)
        #expect(article?.content == nil)
        #expect(article?.author == nil)
        #expect(article?.imageURL == nil)
    }
}

@Suite("GuardianFieldsDTO Tests")
struct GuardianFieldsDTOTests {
    @Test("Can create GuardianFieldsDTO")
    func guardianFieldsDTOInitialization() {
        let fields = GuardianFieldsDTO(
            thumbnail: "https://example.com/image.jpg",
            trailText: "Trail",
            body: "Content",
            byline: "Author"
        )

        #expect(fields.thumbnail == "https://example.com/image.jpg")
        #expect(fields.trailText == "Trail")
        #expect(fields.body == "Content")
        #expect(fields.byline == "Author")
    }

    @Test("All fields can be nil")
    func guardianFieldsDTOAllNil() {
        let fields = GuardianFieldsDTO(
            thumbnail: nil,
            trailText: nil,
            body: nil,
            byline: nil
        )

        #expect(fields.thumbnail == nil)
        #expect(fields.trailText == nil)
        #expect(fields.body == nil)
        #expect(fields.byline == nil)
    }
}

@Suite("GuardianSingleArticleResponse Tests")
struct GuardianSingleArticleResponseTests {
    @Test("Can create single article response")
    func guardianSingleArticleResponseInitialization() {
        let fields = GuardianFieldsDTO(
            thumbnail: "https://example.com/image.jpg",
            trailText: "Trail",
            body: "Content",
            byline: "Author"
        )
        let dto = GuardianArticleDTO(
            id: "article-1",
            type: "article",
            sectionId: "world",
            sectionName: "World news",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Test Article",
            webUrl: "https://example.com/article",
            apiUrl: "https://api.example.com/article",
            fields: fields
        )
        let content = GuardianSingleArticleContent(status: "ok", content: dto)
        let response = GuardianSingleArticleResponse(response: content)

        #expect(response.response.status == "ok")
        #expect(response.response.content.id == "article-1")
    }
}

@Suite("GuardianResponse Codable Tests")
struct GuardianResponseCodableTests {
    @Test("Can encode GuardianResponse")
    func guardianResponseEncodable() throws {
        let content = GuardianResponseContent(
            status: "ok",
            total: 10,
            startIndex: 1,
            pageSize: 10,
            currentPage: 1,
            pages: 1,
            results: []
        )
        let response = GuardianResponse(response: content)

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        #expect(!data.isEmpty)
    }

    @Test("Can decode GuardianResponse")
    func guardianResponseDecodable() throws {
        let jsonString = """
        {
            "response": {
                "status": "ok",
                "total": 10,
                "startIndex": 1,
                "pageSize": 10,
                "currentPage": 1,
                "pages": 1,
                "results": []
            }
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: jsonString.data(using: .utf8)!)

        #expect(response.response.status == "ok")
        #expect(response.response.total == 10)
    }

    @Test("Can decode GuardianArticleDTO")
    func guardianArticleDTODecodable() throws {
        let jsonString = """
        {
            "id": "article-1",
            "type": "article",
            "sectionId": "world",
            "sectionName": "World news",
            "webPublicationDate": "2024-01-15T10:30:00Z",
            "webTitle": "Test Article",
            "webUrl": "https://example.com/article",
            "apiUrl": "https://api.example.com/article",
            "fields": null
        }
        """

        let decoder = JSONDecoder()
        let dto = try decoder.decode(GuardianArticleDTO.self, from: jsonString.data(using: .utf8)!)

        #expect(dto.id == "article-1")
        #expect(dto.webTitle == "Test Article")
    }
}

@Suite("GuardianResponse Integration Tests")
struct GuardianResponseIntegrationTests {
    @Test("Can process multiple articles from response")
    func processMultipleArticles() {
        let dtos = [
            GuardianArticleDTO(
                id: "article-1",
                type: "article",
                sectionId: "world",
                sectionName: "World news",
                webPublicationDate: "2024-01-15T10:30:00Z",
                webTitle: "Article 1",
                webUrl: "https://example.com/1",
                apiUrl: "https://api.example.com/1",
                fields: nil
            ),
            GuardianArticleDTO(
                id: "article-2",
                type: "article",
                sectionId: "technology",
                sectionName: "Technology",
                webPublicationDate: "2024-01-15T09:30:00Z",
                webTitle: "Article 2",
                webUrl: "https://example.com/2",
                apiUrl: "https://api.example.com/2",
                fields: nil
            ),
        ]

        let articles = dtos.compactMap { $0.toArticle() }

        #expect(articles.count == 2)
        #expect(articles[0].title == "Article 1")
        #expect(articles[1].title == "Article 2")
    }
}
