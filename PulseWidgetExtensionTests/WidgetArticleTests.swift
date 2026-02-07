import Foundation
import WidgetKit
import Testing

@Suite("WidgetArticle Tests")
struct WidgetArticleTests {
    @Test("widget article can be instantiated")
    func widgetArticleCanBeInstantiated() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        #expect(article is WidgetArticle)
    }

    @Test("displayTitle returns title when not empty")
    func displayTitleReturnsTitleWhenNotEmpty() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        #expect(article.displayTitle == "Test Article")
    }

    @Test("displayTitle returns Untitled when empty")
    func displayTitleReturnsUntitledWhenEmpty() {
        let article = WidgetArticle(
            id: "1",
            title: "",
            source: "Test Source",
            imageData: nil
        )
        #expect(article.displayTitle == "Untitled")
    }
}
