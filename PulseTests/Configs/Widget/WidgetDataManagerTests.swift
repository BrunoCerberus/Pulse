import Foundation
@testable import Pulse
import Testing

@Suite("WidgetDataManager Tests")
struct WidgetDataManagerTests {
    // MARK: - SharedWidgetArticle Encoding Tests

    @Test("SharedWidgetArticle encodes correctly")
    func sharedWidgetArticleEncodesCorrectly() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "Test Title",
            source: "Test Source",
            imageURL: "https://example.com/image.jpg"
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.id == article.id)
        #expect(decoded.title == article.title)
        #expect(decoded.source == article.source)
        #expect(decoded.imageURL == article.imageURL)
    }

    @Test("SharedWidgetArticle handles nil source")
    func sharedWidgetArticleHandlesNilSource() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "Test Title",
            source: nil,
            imageURL: "https://example.com/image.jpg"
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.source == nil)
    }

    @Test("SharedWidgetArticle handles nil imageURL")
    func sharedWidgetArticleHandlesNilImageURL() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "Test Title",
            source: "Source",
            imageURL: nil
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.imageURL == nil)
    }

    @Test("SharedWidgetArticle array encodes correctly")
    func sharedWidgetArticleArrayEncodesCorrectly() throws {
        let articles = [
            SharedWidgetArticle(id: "1", title: "Title 1", source: "Source 1", imageURL: nil),
            SharedWidgetArticle(id: "2", title: "Title 2", source: nil, imageURL: "https://example.com/2.jpg"),
            SharedWidgetArticle(id: "3", title: "Title 3", source: "Source 3", imageURL: "https://example.com/3.jpg"),
        ]

        let encoded = try JSONEncoder().encode(articles)
        let decoded = try JSONDecoder().decode([SharedWidgetArticle].self, from: encoded)

        #expect(decoded.count == 3)
        #expect(decoded[0].id == "1")
        #expect(decoded[1].id == "2")
        #expect(decoded[2].id == "3")
    }

    @Test("SharedWidgetArticle handles special characters in title")
    func sharedWidgetArticleHandlesSpecialCharacters() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "Breaking: \"Special\" chars & symbols <test>",
            source: "Source's Name",
            imageURL: nil
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.title == article.title)
        #expect(decoded.source == article.source)
    }

    @Test("SharedWidgetArticle handles unicode in title")
    func sharedWidgetArticleHandlesUnicode() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "日本語ニュース 🇯🇵 Breaking 中文",
            source: "国際ニュース",
            imageURL: nil
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.title == article.title)
        #expect(decoded.source == article.source)
    }

    @Test("SharedWidgetArticle handles empty title")
    func sharedWidgetArticleHandlesEmptyTitle() throws {
        let article = SharedWidgetArticle(
            id: "test-id",
            title: "",
            source: "Source",
            imageURL: nil
        )

        let encoded = try JSONEncoder().encode(article)
        let decoded = try JSONDecoder().decode(SharedWidgetArticle.self, from: encoded)

        #expect(decoded.title == "")
    }

    // MARK: - Article to SharedWidgetArticle Conversion Tests

    @Test("Article converts to SharedWidgetArticle with all fields")
    func articleConvertsWithAllFields() {
        let article = Article.mockArticles[0]

        let shared = SharedWidgetArticle(
            id: article.id,
            title: article.title,
            source: article.source.name,
            imageURL: article.imageURL
        )

        #expect(shared.id == article.id)
        #expect(shared.title == article.title)
        #expect(shared.source == article.source.name)
        #expect(shared.imageURL == article.imageURL)
    }

    @Test("Multiple articles convert correctly")
    func multipleArticlesConvert() {
        let articles = Article.mockArticles

        let sharedArticles = articles.map { article in
            SharedWidgetArticle(
                id: article.id,
                title: article.title,
                source: article.source.name,
                imageURL: article.imageURL
            )
        }

        #expect(sharedArticles.count == articles.count)
        for (index, shared) in sharedArticles.enumerated() {
            #expect(shared.id == articles[index].id)
        }
    }

    @Test("Prefix 10 articles conversion")
    func prefixTenArticlesConversion() throws {
        // Generate 15 articles
        let articles = (1 ... 15).map { index in
            Article(
                id: "article-\(index)",
                title: "Article \(index)",
                description: nil,
                content: nil,
                author: nil,
                source: ArticleSource(id: nil, name: "Source"),
                url: "https://example.com/\(index)",
                imageURL: nil,
                publishedAt: Date(),
                category: nil
            )
        }

        // Widget should only take first 10
        let sharedArticles = articles.prefix(10).map { article in
            SharedWidgetArticle(
                id: article.id,
                title: article.title,
                source: article.source.name,
                imageURL: article.imageURL
            )
        }

        #expect(sharedArticles.count == 10)
        #expect(sharedArticles.last?.id == "article-10")
    }
}
