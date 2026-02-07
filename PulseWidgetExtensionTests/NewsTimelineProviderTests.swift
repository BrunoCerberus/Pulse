import Foundation
import WidgetKit
import Testing

@Suite("NewsTimelineProvider Tests")
struct NewsTimelineProviderTests {
    @Test("provider can be instantiated")
    func providerCanBeInstantiated() {
        let provider = NewsTimelineProvider()
        #expect(type(of: provider) == NewsTimelineProvider.self)
    }
}

@Suite("NewsTimelineEntry Tests")
struct NewsTimelineEntryTests {
    @Test("entry stores date")
    func entryStoresDate() {
        let date = Date()
        let entry = NewsTimelineEntry(date: date, articles: nil, family: .systemSmall)
        #expect(entry.date == date)
    }

    @Test("entry stores nil articles")
    func entryStoresNilArticles() {
        let entry = NewsTimelineEntry(date: Date(), articles: nil, family: .systemSmall)
        #expect(entry.articles == nil)
    }

    @Test("entry stores articles when provided")
    func entryStoresArticlesWhenProvided() {
        let articles = [
            WidgetArticle(id: "1", title: "Test", source: "Source", imageData: nil),
        ]
        let entry = NewsTimelineEntry(date: Date(), articles: articles, family: .systemMedium)
        #expect(entry.articles?.count == 1)
        #expect(entry.articles?[0].id == "1")
    }

    @Test("entry stores correct family")
    func entryStoresCorrectFamily() {
        let entry = NewsTimelineEntry(date: Date(), articles: nil, family: .systemLarge)
        #expect(entry.family == .systemLarge)
    }
}
