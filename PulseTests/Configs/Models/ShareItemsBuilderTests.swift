import Foundation
@testable import Pulse
import Testing

@Suite("ShareItemsBuilder Tests")
struct ShareItemsBuilderTests {
    let testArticle = Article.mockArticles[0]

    @Test("Returns string and URL for valid article URL")
    func validURLReturnsStringAndURL() {
        let items = ShareItemsBuilder.activityItems(for: testArticle)

        #expect(items.count == 2)
        #expect(items[0] is String)
        #expect(items[1] is URL)
    }

    @Test("Share text contains article title and source name")
    func shareTextContainsTitleAndSource() {
        let items = ShareItemsBuilder.activityItems(for: testArticle)

        let text = items[0] as? String
        #expect(text?.contains(testArticle.title) == true)
        #expect(text?.contains(testArticle.source.name) == true)
    }

    @Test("Share text uses em dash separator")
    func shareTextUsesEmDashSeparator() {
        let items = ShareItemsBuilder.activityItems(for: testArticle)

        let text = items[0] as? String
        let expected = "\(testArticle.title) — \(testArticle.source.name)"
        #expect(text == expected)
    }

    @Test("Returns only string for invalid URL")
    func invalidURLReturnsOnlyString() {
        let article = Article(
            id: "test",
            title: "Test Title",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: "test", name: "Test Source"),
            url: "",
            imageURL: nil,
            thumbnailURL: nil,
            publishedAt: Date(),
            category: nil,
            mediaType: nil,
            mediaURL: nil,
            mediaDuration: nil,
            mediaMimeType: nil
        )

        let items = ShareItemsBuilder.activityItems(for: article)

        #expect(items.count == 1)
        #expect(items[0] is String)
    }
}
