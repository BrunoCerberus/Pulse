import Foundation
import WidgetKit
import Testing

@Suite("SharedArticle Tests")
struct SharedArticleTests {
    @Test("shared article can be instantiated")
    func sharedArticleCanBeInstantiated() {
        let article = SharedArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageURL: "https://example.com/image.jpg"
        )
        #expect(article is SharedArticle)
    }

    @Test("displayTitle returns title when not empty")
    func displayTitleReturnsTitleWhenNotEmpty() {
        let article = SharedArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageURL: nil
        )
        #expect(article.displayTitle == "Test Article")
    }

    @Test("displayTitle returns Untitled when empty")
    func displayTitleReturnsUntitledWhenEmpty() {
        let article = SharedArticle(
            id: "1",
            title: "",
            source: "Test Source",
            imageURL: nil
        )
        #expect(article.displayTitle == "Untitled")
    }

    @Test("shared article is Codable")
    func sharedArticleIsCodable() {
        let article = SharedArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageURL: "https://example.com/image.jpg"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(article)
            let decodedArticle = try decoder.decode(SharedArticle.self, from: data)
            #expect(decodedArticle.id == article.id)
            #expect(decodedArticle.title == article.title)
        } catch {
            Issue.record("Failed to encode/decode SharedArticle: \(error)")
        }
    }
}
