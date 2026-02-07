import Foundation
@testable import PulseWidgetExtension
import Testing

@Suite("SharedDataManager Tests")
struct SharedDataManagerTests {
    @Test("shared returns singleton")
    func sharedReturnsSingleton() {
        let manager1 = SharedDataManager.shared
        let manager2 = SharedDataManager.shared
        #expect(manager1 === manager2)
    }

    @Test("getArticles returns empty array when no data")
    func getArticlesReturnsEmptyArrayWhenNoData() {
        let manager = SharedDataManager()
        let articles = manager.getArticles()
        #expect(articles.isEmpty)
    }

    @Test("saveArticles saves articles")
    func saveArticlesSavesArticles() {
        let manager = SharedDataManager()

        let articles = [
            SharedArticle(
                id: "1",
                title: "Test Article 1",
                source: "Source 1",
                imageURL: "https://example.com/image1.jpg"
            ),
            SharedArticle(
                id: "2",
                title: "Test Article 2",
                source: "Source 2",
                imageURL: "https://example.com/image2.jpg"
            ),
        ]

        manager.saveArticles(articles)

        let savedArticles = manager.getArticles()
        #expect(savedArticles.count == 2)
    }

    @Test("saveArticles handles empty array")
    func saveArticlesHandlesEmptyArray() {
        let manager = SharedDataManager()
        manager.saveArticles([])
        let articles = manager.getArticles()
        #expect(articles.isEmpty)
    }
}
