import Foundation
@testable import Pulse
import Testing

@Suite("ReadArticle Tests")
struct ReadArticleTests {
    private func makeArticle(
        id: String = "test-id",
        title: String = "Test Title",
        description: String? = "Test description",
        content: String? = "Test content",
        author: String? = "Test Author",
        sourceName: String = "TestSource",
        sourceID: String? = "test-source",
        url: String = "https://example.com/article",
        imageURL: String? = "https://example.com/image.jpg",
        publishedAt: Date = Date(timeIntervalSince1970: 1_000_000),
        category: NewsCategory? = .technology
    ) -> Article {
        Article(
            id: id,
            title: title,
            description: description,
            content: content,
            author: author,
            source: ArticleSource(id: sourceID, name: sourceName),
            url: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            category: category
        )
    }

    @Test("Init from Article copies all fields correctly")
    func initFromArticle() {
        let article = makeArticle()
        let readArticle = ReadArticle(from: article)

        #expect(readArticle.articleID == "test-id")
        #expect(readArticle.title == "Test Title")
        #expect(readArticle.articleDescription == "Test description")
        #expect(readArticle.content == "Test content")
        #expect(readArticle.author == "Test Author")
        #expect(readArticle.sourceName == "TestSource")
        #expect(readArticle.sourceID == "test-source")
        #expect(readArticle.url == "https://example.com/article")
        #expect(readArticle.imageURL == "https://example.com/image.jpg")
        #expect(readArticle.category == "technology")
    }

    @Test("Init from Article with nil optional fields")
    func initFromArticleNilFields() {
        let article = makeArticle(
            description: nil,
            content: nil,
            author: nil,
            sourceID: nil,
            imageURL: nil,
            category: nil
        )
        let readArticle = ReadArticle(from: article)

        #expect(readArticle.articleDescription == nil)
        #expect(readArticle.content == nil)
        #expect(readArticle.author == nil)
        #expect(readArticle.sourceID == nil)
        #expect(readArticle.imageURL == nil)
        #expect(readArticle.category == nil)
    }

    @Test("Init sets readAt to approximately now")
    func initSetsReadAtToNow() {
        let beforeCreation = Date()
        let readArticle = ReadArticle(from: makeArticle())
        let afterCreation = Date()

        #expect(readArticle.readAt >= beforeCreation)
        #expect(readArticle.readAt <= afterCreation)
    }

    @Test("toArticle reconstructs Article correctly")
    func toArticleReconstruction() {
        let originalDate = Date(timeIntervalSince1970: 1_000_000)
        let article = makeArticle(publishedAt: originalDate)
        let readArticle = ReadArticle(from: article)
        let reconstructed = readArticle.toArticle()

        #expect(reconstructed.id == article.id)
        #expect(reconstructed.title == article.title)
        #expect(reconstructed.description == article.description)
        #expect(reconstructed.content == article.content)
        #expect(reconstructed.author == article.author)
        #expect(reconstructed.source.id == article.source.id)
        #expect(reconstructed.source.name == article.source.name)
        #expect(reconstructed.url == article.url)
        #expect(reconstructed.imageURL == article.imageURL)
        #expect(reconstructed.publishedAt == originalDate)
        #expect(reconstructed.category == .technology)
    }

    @Test("toArticle with nil category returns nil")
    func toArticleNilCategory() {
        let article = makeArticle(category: nil)
        let readArticle = ReadArticle(from: article)
        let reconstructed = readArticle.toArticle()

        #expect(reconstructed.category == nil)
    }

    @Test("toArticle with invalid category rawValue returns nil")
    func toArticleInvalidCategory() {
        let article = makeArticle(category: nil)
        let readArticle = ReadArticle(from: article)
        readArticle.category = "invalid_category"
        let reconstructed = readArticle.toArticle()

        #expect(reconstructed.category == nil)
    }

    @Test("Category roundtrip preserves all NewsCategory values")
    func categoryRoundtrip() {
        let categories: [NewsCategory] = [.technology, .science, .business, .sports, .entertainment, .health]
        for category in categories {
            let article = makeArticle(category: category)
            let readArticle = ReadArticle(from: article)
            let reconstructed = readArticle.toArticle()
            #expect(reconstructed.category == category, "Category \(category) should survive roundtrip")
        }
    }
}
