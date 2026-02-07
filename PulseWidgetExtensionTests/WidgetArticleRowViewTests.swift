import Foundation
import WidgetKit
import Testing

@Suite("ArticleRowView Tests")
struct WidgetArticleRowViewTests {
    @Test("article row view stores article data")
    func articleRowViewStoresArticleData() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view.article.id == "1")
        #expect(view.article.title == "Test Article")
        #expect(view.article.source == "Test Source")
    }

    @Test("article row view stores nil image data when absent")
    func articleRowViewStoresNilImageData() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view.article.imageData == nil)
    }

    @Test("article row view stores image data when provided")
    func articleRowViewStoresImageData() {
        let imageData = Data(count: 100)
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: imageData
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view.article.imageData == imageData)
    }
}
