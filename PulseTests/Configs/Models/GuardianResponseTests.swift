import Foundation
@testable import Pulse
import Testing

@Suite("GuardianResponse Model Tests")
struct GuardianResponseTests {
    // MARK: - JSON Test Data

    private var validJSON: String {
        """
        {
            "response": {
                "status": "ok",
                "total": 100,
                "startIndex": 1,
                "pageSize": 20,
                "currentPage": 1,
                "pages": 5,
                "results": [
                    {
                        "id": "world/2024/jan/01/test-article",
                        "type": "article",
                        "sectionId": "world",
                        "sectionName": "World news",
                        "webPublicationDate": "2024-01-01T12:00:00Z",
                        "webTitle": "Test Article Title",
                        "webUrl": "https://www.theguardian.com/world/2024/jan/01/test-article",
                        "apiUrl": "https://content.guardianapis.com/world/2024/jan/01/test-article",
                        "fields": {
                            "thumbnail": "https://example.com/image.jpg",
                            "trailText": "This is the trail text description",
                            "body": "<p>Full article body content</p>",
                            "byline": "John Doe"
                        }
                    }
                ]
            }
        }
        """
    }

    private var jsonWithMissingFields: String {
        """
        {
            "response": {
                "status": "ok",
                "total": 50,
                "startIndex": 1,
                "pageSize": 10,
                "currentPage": 1,
                "pages": 5,
                "results": [
                    {
                        "id": "tech/2024/jan/02/minimal-article",
                        "type": "article",
                        "sectionId": "technology",
                        "sectionName": "Technology",
                        "webPublicationDate": "2024-01-02T10:30:00Z",
                        "webTitle": "Minimal Article",
                        "webUrl": "https://www.theguardian.com/tech/2024/jan/02/minimal-article",
                        "apiUrl": "https://content.guardianapis.com/tech/2024/jan/02/minimal-article"
                    }
                ]
            }
        }
        """
    }

    private var jsonWithFractionalSeconds: String {
        """
        {
            "response": {
                "status": "ok",
                "total": 1,
                "startIndex": 1,
                "pageSize": 1,
                "currentPage": 1,
                "pages": 1,
                "results": [
                    {
                        "id": "test/fractional-date",
                        "type": "article",
                        "sectionId": "world",
                        "sectionName": "World",
                        "webPublicationDate": "2024-01-01T12:00:00.123Z",
                        "webTitle": "Fractional Seconds Article",
                        "webUrl": "https://www.theguardian.com/test/fractional-date",
                        "apiUrl": "https://content.guardianapis.com/test/fractional-date"
                    }
                ]
            }
        }
        """
    }

    // MARK: - Decoding Tests

    @Test("GuardianResponse decodes from valid JSON")
    func decodesFromValidJSON() throws {
        let data = validJSON.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(GuardianResponse.self, from: data)

        #expect(response.response.status == "ok")
        #expect(response.response.total == 100)
        #expect(response.response.startIndex == 1)
        #expect(response.response.pageSize == 20)
        #expect(response.response.currentPage == 1)
        #expect(response.response.pages == 5)
        #expect(response.response.results.count == 1)
    }

    @Test("GuardianResponse handles missing optional fields")
    func handlesMissingOptionalFields() throws {
        let data = jsonWithMissingFields.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(GuardianResponse.self, from: data)

        #expect(response.response.results.count == 1)

        let article = response.response.results[0]
        #expect(article.fields == nil)
        #expect(article.id == "tech/2024/jan/02/minimal-article")
    }

    // MARK: - toArticle Conversion Tests

    @Test("toArticle conversion maps fields correctly")
    func toArticleMapsFieldsCorrectly() throws {
        let data = validJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.id == "world/2024/jan/01/test-article")
        #expect(article?.title == "Test Article Title")
        #expect(article?.description == "This is the trail text description")
        #expect(article?.content == "<p>Full article body content</p>")
        #expect(article?.author == "John Doe")
        #expect(article?.source.id == "guardian")
        #expect(article?.source.name == "World news")
        #expect(article?.url == "https://www.theguardian.com/world/2024/jan/01/test-article")
        #expect(article?.imageURL == "https://example.com/image.jpg")
        #expect(article?.category == .world)
    }

    @Test("toArticle handles nil fields gracefully")
    func toArticleHandlesNilFields() throws {
        let data = jsonWithMissingFields.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.description == nil)
        #expect(article?.content == nil)
        #expect(article?.author == nil)
        #expect(article?.imageURL == nil)
    }

    @Test("toArticle defaults to world category for unmapped sections")
    func toArticleDefaultsToWorldForUnmappedSections() throws {
        // Create JSON with unknown section (defaults to .world)
        let jsonWithUnknownSection = """
        {
            "response": {
                "status": "ok",
                "total": 1,
                "startIndex": 1,
                "pageSize": 1,
                "currentPage": 1,
                "pages": 1,
                "results": [
                    {
                        "id": "unknown/section/article",
                        "type": "article",
                        "sectionId": "commentisfree",
                        "sectionName": "Opinion",
                        "webPublicationDate": "2024-01-01T12:00:00Z",
                        "webTitle": "Opinion Article",
                        "webUrl": "https://www.theguardian.com/unknown/article",
                        "apiUrl": "https://content.guardianapis.com/unknown/article"
                    }
                ]
            }
        }
        """

        let data = jsonWithUnknownSection.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle()

        #expect(article != nil)
        // "commentisfree" doesn't map to a known NewsCategory, defaults to .world
        #expect(article?.category == .world)
    }

    @Test("toArticle with explicit category overrides section mapping")
    func toArticleWithExplicitCategory() throws {
        let data = validJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle(category: .technology)

        #expect(article != nil)
        #expect(article?.category == .technology) // Explicit category should override
    }

    @Test("toArticle parses date with fractional seconds")
    func toArticleParsesDateWithFractionalSeconds() throws {
        let data = jsonWithFractionalSeconds.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }

    @Test("toArticle parses date without fractional seconds")
    func toArticleParsesDateWithoutFractionalSeconds() throws {
        let data = validJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GuardianResponse.self, from: data)

        let dto = response.response.results[0]
        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.publishedAt != nil)
    }
}

@Suite("GuardianArticleDTO Tests")
struct GuardianArticleDTOTests {
    @Test("GuardianArticleDTO decodes all fields")
    func decodesAllFields() throws {
        let json = """
        {
            "id": "test/article",
            "type": "article",
            "sectionId": "technology",
            "sectionName": "Technology",
            "webPublicationDate": "2024-01-01T12:00:00Z",
            "webTitle": "Test Article",
            "webUrl": "https://www.theguardian.com/test/article",
            "apiUrl": "https://content.guardianapis.com/test/article",
            "fields": {
                "thumbnail": "https://example.com/thumb.jpg",
                "trailText": "Trail text",
                "body": "<p>Body</p>",
                "byline": "Author Name"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(GuardianArticleDTO.self, from: data)

        #expect(dto.id == "test/article")
        #expect(dto.type == "article")
        #expect(dto.sectionId == "technology")
        #expect(dto.sectionName == "Technology")
        #expect(dto.webTitle == "Test Article")
        #expect(dto.webUrl == "https://www.theguardian.com/test/article")
        #expect(dto.apiUrl == "https://content.guardianapis.com/test/article")
        #expect(dto.fields?.thumbnail == "https://example.com/thumb.jpg")
        #expect(dto.fields?.trailText == "Trail text")
        #expect(dto.fields?.body == "<p>Body</p>")
        #expect(dto.fields?.byline == "Author Name")
    }

    @Test("toArticle returns nil for invalid date")
    func returnsNilForInvalidDate() throws {
        let json = """
        {
            "id": "test/invalid-date",
            "type": "article",
            "sectionId": "world",
            "sectionName": "World",
            "webPublicationDate": "not-a-valid-date",
            "webTitle": "Invalid Date Article",
            "webUrl": "https://www.theguardian.com/test/invalid-date",
            "apiUrl": "https://content.guardianapis.com/test/invalid-date"
        }
        """

        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(GuardianArticleDTO.self, from: data)

        let article = dto.toArticle()

        #expect(article == nil)
    }
}

@Suite("GuardianSingleArticleResponse Tests")
struct GuardianSingleArticleResponseTests {
    @Test("GuardianSingleArticleResponse decodes correctly")
    func decodesCorrectly() throws {
        let json = """
        {
            "response": {
                "status": "ok",
                "content": {
                    "id": "single/article",
                    "type": "article",
                    "sectionId": "science",
                    "sectionName": "Science",
                    "webPublicationDate": "2024-01-01T12:00:00Z",
                    "webTitle": "Single Article",
                    "webUrl": "https://www.theguardian.com/single/article",
                    "apiUrl": "https://content.guardianapis.com/single/article"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GuardianSingleArticleResponse.self, from: data)

        #expect(response.response.status == "ok")
        #expect(response.response.content.id == "single/article")
        #expect(response.response.content.webTitle == "Single Article")
    }
}
