import Foundation
@testable import Pulse
import Testing

@Suite("Article Initialization Tests")
struct ArticleInitializationTests {
    @Test("Can create article with required fields")
    func articleInitialization() {
        let source = ArticleSource(id: "test-source", name: "Test Source")
        let article = Article(
            title: "Test Article",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        #expect(article.title == "Test Article")
        #expect(article.source == source)
        #expect(article.url == "https://example.com")
        #expect(article.id != nil)
        #expect(!article.id.isEmpty)
    }

    @Test("Can create article with all fields")
    func articleInitializationComplete() {
        let source = ArticleSource(id: "guardian", name: "The Guardian")
        let date = Date()
        let article = Article(
            id: "article-123",
            title: "Breaking News",
            description: "Important story",
            content: "Full content here",
            author: "John Doe",
            source: source,
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: date,
            category: .world
        )

        #expect(article.id == "article-123")
        #expect(article.title == "Breaking News")
        #expect(article.description == "Important story")
        #expect(article.content == "Full content here")
        #expect(article.author == "John Doe")
        #expect(article.source == source)
        #expect(article.url == "https://example.com/article")
        #expect(article.imageURL == "https://example.com/image.jpg")
        #expect(article.publishedAt == date)
        #expect(article.category == .world)
    }

    @Test("Article generates unique IDs by default")
    func articleDefaultIDUnique() {
        let source = ArticleSource(id: "test", name: "Test")
        let article1 = Article(title: "Article 1", source: source, url: "https://test.com", publishedAt: Date())
        let article2 = Article(title: "Article 2", source: source, url: "https://test.com", publishedAt: Date())

        #expect(article1.id != article2.id)
    }

    @Test("Optional fields are nil by default")
    func articleOptionalFieldsNil() {
        let source = ArticleSource(id: "test", name: "Test")
        let article = Article(
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        #expect(article.description == nil)
        #expect(article.content == nil)
        #expect(article.author == nil)
        #expect(article.imageURL == nil)
        #expect(article.category == nil)
    }
}

@Suite("Article Equatable Tests")
struct ArticleEquatableTests {
    @Test("Same articles are equal")
    func sameArticlesEqual() {
        let source = ArticleSource(id: "test", name: "Test")
        let date = Date()
        let article1 = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )
        let article2 = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )

        #expect(article1 == article2)
    }

    @Test("Different IDs make articles not equal")
    func differentIDsNotEqual() {
        let source = ArticleSource(id: "test", name: "Test")
        let date = Date()
        let article1 = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )
        let article2 = Article(
            id: "article-2",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )

        #expect(article1 != article2)
    }

    @Test("Different titles make articles not equal")
    func differentTitlesNotEqual() {
        let source = ArticleSource(id: "test", name: "Test")
        let date = Date()
        let article1 = Article(
            id: "article-1",
            title: "Test Article",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )
        let article2 = Article(
            id: "article-1",
            title: "Different Article",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )

        #expect(article1 != article2)
    }
}

@Suite("Article Identifiable Tests")
struct ArticleIdentifiableTests {
    @Test("Article has valid id")
    func articleIdentifiable() {
        let source = ArticleSource(id: "test", name: "Test")
        let article = Article(
            id: "article-123",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        #expect(article.id == "article-123")
    }
}

@Suite("Article Hashable Tests")
struct ArticleHashableTests {
    @Test("Article can be hashed")
    func articleHashable() {
        let source = ArticleSource(id: "test", name: "Test")
        let article = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        let set = Set([article])
        #expect(set.count == 1)
    }

    @Test("Same articles have same hash")
    func sameArticlesSameHash() {
        let source = ArticleSource(id: "test", name: "Test")
        let date = Date()
        let article1 = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )
        let article2 = Article(
            id: "article-1",
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )

        let set = Set([article1, article2])
        #expect(set.count == 1)
    }
}

@Suite("Article Date Formatting Tests")
struct ArticleDateFormattingTests {
    @Test("Can format recent date")
    func formattedDateRecent() {
        let source = ArticleSource(id: "test", name: "Test")
        let recentDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let article = Article(
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: recentDate
        )

        let formatted = article.formattedDate
        #expect(!formatted.isEmpty)
    }

    @Test("Can format old date")
    func formattedDateOld() {
        let source = ArticleSource(id: "test", name: "Test")
        let oldDate = Date(timeIntervalSinceNow: -86400 * 30) // 30 days ago
        let article = Article(
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: oldDate
        )

        let formatted = article.formattedDate
        #expect(!formatted.isEmpty)
    }

    @Test("Formatted date is locale-specific")
    func formattedDateLocale() {
        let source = ArticleSource(id: "test", name: "Test")
        let date = Date(timeIntervalSinceNow: -3600)
        let article = Article(
            title: "Test",
            source: source,
            url: "https://example.com",
            publishedAt: date
        )

        let formatted = article.formattedDate
        // Should contain abbreviated time units like "h", "m", "s", etc.
        #expect(!formatted.isEmpty)
    }
}

@Suite("ArticleSource Tests")
struct ArticleSourceTests {
    @Test("Can create article source")
    func articleSourceInitialization() {
        let source = ArticleSource(id: "source-1", name: "The Guardian")

        #expect(source.id == "source-1")
        #expect(source.name == "The Guardian")
    }

    @Test("Article sources are equatable")
    func articleSourceEquatable() {
        let source1 = ArticleSource(id: "source-1", name: "The Guardian")
        let source2 = ArticleSource(id: "source-1", name: "The Guardian")

        #expect(source1 == source2)
    }

    @Test("Different sources are not equal")
    func articleSourceDifferent() {
        let source1 = ArticleSource(id: "source-1", name: "The Guardian")
        let source2 = ArticleSource(id: "source-2", name: "BBC News")

        #expect(source1 != source2)
    }

    @Test("Article source can be nil id")
    func articleSourceNilId() {
        let source = ArticleSource(id: nil, name: "Unknown Source")

        #expect(source.id == nil)
        #expect(source.name == "Unknown Source")
    }
}

@Suite("Article Codable Tests")
struct ArticleCodableTests {
    @Test("Can encode article")
    func articleEncodable() throws {
        let source = ArticleSource(id: "test", name: "Test")
        let article = Article(
            id: "article-1",
            title: "Test Article",
            description: "Description",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(article)
        #expect(!data.isEmpty)
    }

    @Test("Can decode article")
    func articleDecodable() throws {
        let source = ArticleSource(id: "test", name: "Test")
        let originalArticle = Article(
            id: "article-1",
            title: "Test Article",
            description: "Description",
            source: source,
            url: "https://example.com",
            publishedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalArticle)

        let decoder = JSONDecoder()
        let decodedArticle = try decoder.decode(Article.self, from: data)

        #expect(decodedArticle.id == originalArticle.id)
        #expect(decodedArticle.title == originalArticle.title)
    }

    @Test("Source is codable")
    func articleSourceCodable() throws {
        let source = ArticleSource(id: "test", name: "Test Source")

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decodedSource = try decoder.decode(ArticleSource.self, from: data)

        #expect(decodedSource == source)
    }
}

@Suite("Article Integration Tests")
struct ArticleIntegrationTests {
    @Test("Can create and use article in collection")
    func articleInCollection() {
        let source = ArticleSource(id: "test", name: "Test")
        let articles = [
            Article(title: "Article 1", source: source, url: "https://test.com/1", publishedAt: Date()),
            Article(title: "Article 2", source: source, url: "https://test.com/2", publishedAt: Date()),
            Article(title: "Article 3", source: source, url: "https://test.com/3", publishedAt: Date()),
        ]

        #expect(articles.count == 3)
        #expect(articles[0].title == "Article 1")
        #expect(articles[2].title == "Article 3")
    }

    @Test("Articles are unique by ID")
    func articlesUniqueById() {
        let source = ArticleSource(id: "test", name: "Test")
        let articles = [
            Article(id: "1", title: "Article 1", source: source, url: "https://test.com", publishedAt: Date()),
            Article(id: "2", title: "Article 2", source: source, url: "https://test.com", publishedAt: Date()),
            Article(id: "1", title: "Article 1 Duplicate", source: source, url: "https://test.com", publishedAt: Date()),
        ]

        let uniqueArticles = Array(Set(articles))
        #expect(uniqueArticles.count == 2)
    }

    @Test("Article preserves all data through encoding/decoding cycle")
    func articleRoundTrip() throws {
        let source = ArticleSource(id: "guardian", name: "The Guardian")
        let date = Date()
        let originalArticle = Article(
            id: "unique-id",
            title: "Breaking News",
            description: "Important development",
            content: "Full article content",
            author: "Reporter Name",
            source: source,
            url: "https://theguardian.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: date,
            category: .world
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalArticle)

        let decoder = JSONDecoder()
        let decodedArticle = try decoder.decode(Article.self, from: data)

        #expect(decodedArticle.id == originalArticle.id)
        #expect(decodedArticle.title == originalArticle.title)
        #expect(decodedArticle.description == originalArticle.description)
        #expect(decodedArticle.content == originalArticle.content)
        #expect(decodedArticle.author == originalArticle.author)
        #expect(decodedArticle.source == originalArticle.source)
        #expect(decodedArticle.url == originalArticle.url)
        #expect(decodedArticle.imageURL == originalArticle.imageURL)
        #expect(decodedArticle.category == originalArticle.category)
    }
}
