import Foundation
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
                imageURL: "https://example.com/image1.jpg",
            ),
            SharedArticle(
                id: "2",
                title: "Test Article 2",
                source: "Source 2",
                imageURL: "https://example.com/image2.jpg",
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

    @Test("getArticles caps at maxArticlesCount keeping first items")
    func getArticlesCapsAtMax() {
        let manager = SharedDataManager()

        let articles = Array(0 ..< 15).map { index in
            SharedArticle(
                id: String(index),
                title: "Test Article \(index)",
                source: "Source \(index)",
                imageURL: "https://example.com/image\(index).jpg",
            )
        }

        manager.saveArticles(articles)

        let savedArticles = manager.getArticles()
        #expect(savedArticles.count == 10)
        // prefix keeps the FIRST items, not the last (suffix would keep last)
        #expect(savedArticles[0].id == "0")
        #expect(savedArticles[9].id == "9")
    }

    @Test("getArticles returns all when under cap")
    func getArticlesReturnsAllWhenUnderCap() {
        let manager = SharedDataManager()

        let articles = Array(0 ..< 5).map { index in
            SharedArticle(
                id: String(index),
                title: "Test Article \(index)",
                source: "Source \(index)",
                imageURL: "https://example.com/image\(index).jpg",
            )
        }

        manager.saveArticles(articles)

        let savedArticles = manager.getArticles()
        #expect(savedArticles.count == 5)
    }
}
