import Foundation
@testable import Pulse
import Testing

@Suite("Guardian API Extended Contract Tests")
struct GuardianAPIExtendedContractTests {
    @Test("Decodes Guardian response with empty results array")
    func decodesEmptyResults() throws {
        let json = """
        {
            "response": {
                "status": "ok",
                "total": 0,
                "startIndex": 0,
                "pageSize": 20,
                "currentPage": 1,
                "pages": 0,
                "results": []
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder().decode(GuardianResponse.self, from: data)

        #expect(response.response.results.isEmpty)
        #expect(response.response.total == 0)
    }

    @Test("Decodes Guardian response with multiple articles")
    func decodesMultipleArticles() throws {
        let json = """
        {
            "response": {
                "status": "ok",
                "total": 3,
                "startIndex": 1,
                "pageSize": 20,
                "currentPage": 1,
                "pages": 1,
                "results": [
                    {
                        "id": "world/2026/article-1",
                        "type": "article",
                        "sectionId": "world",
                        "sectionName": "World news",
                        "webPublicationDate": "2026-01-01T12:00:00Z",
                        "webTitle": "Article One",
                        "webUrl": "https://www.theguardian.com/world/2026/article-1",
                        "apiUrl": "https://content.guardianapis.com/world/2026/article-1"
                    },
                    {
                        "id": "tech/2026/article-2",
                        "type": "article",
                        "sectionId": "technology",
                        "sectionName": "Technology",
                        "webPublicationDate": "2026-01-02T10:00:00Z",
                        "webTitle": "Article Two",
                        "webUrl": "https://www.theguardian.com/tech/2026/article-2",
                        "apiUrl": "https://content.guardianapis.com/tech/2026/article-2"
                    },
                    {
                        "id": "sport/2026/article-3",
                        "type": "article",
                        "sectionId": "sport",
                        "sectionName": "Sport",
                        "webPublicationDate": "2026-01-03T08:00:00Z",
                        "webTitle": "Article Three",
                        "webUrl": "https://www.theguardian.com/sport/2026/article-3",
                        "apiUrl": "https://content.guardianapis.com/sport/2026/article-3"
                    }
                ]
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder().decode(GuardianResponse.self, from: data)

        #expect(response.response.results.count == 3)
        #expect(response.response.results[0].id == "world/2026/article-1")
        #expect(response.response.results[1].sectionId == "technology")
        #expect(response.response.results[2].webTitle == "Article Three")
    }

    @Test("Guardian article with HTML body content is preserved")
    func htmlBodyContentPreserved() throws {
        // swiftlint:disable:next line_length
        let htmlBody = "<h2>Subtitle</h2><p>Paragraph with <strong>bold</strong> and <a href='link'>link</a></p><ul><li>Item</li></ul>"
        let json = """
        {
            "id": "test/html-body",
            "type": "article",
            "sectionId": "technology",
            "sectionName": "Technology",
            "webPublicationDate": "2026-01-01T12:00:00Z",
            "webTitle": "HTML Article",
            "webUrl": "https://www.theguardian.com/test/html-body",
            "apiUrl": "https://content.guardianapis.com/test/html-body",
            "fields": {
                "body": "\(htmlBody)"
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(GuardianArticleDTO.self, from: data)
        let article = dto.toArticle()

        #expect(article != nil)
        #expect(article?.content?.contains("<h2>Subtitle</h2>") == true)
        #expect(article?.content?.contains("<strong>bold</strong>") == true)
        #expect(article?.content?.contains("<a href='link'>link</a>") == true)
    }
}
