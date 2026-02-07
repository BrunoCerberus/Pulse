import Foundation
import WidgetKit
@testable import PulseWidgetExtension
import Testing

@Suite("NewsTimelineProvider Tests")
struct NewsTimelineProviderTests {
    @Test("placeholder returns correct entry")
    func placeholderReturnsCorrectEntry() {
        let provider = NewsTimelineProvider()
        let entry = provider.placeholder(in: .mock)

        #expect(entry.date is Date)
        #expect(entry.articles == nil)
        #expect(entry.family == .systemSmall)
    }

    @Test("getSnapshot returns empty when no articles")
    func getSnapshotReturnsEmptyWhenNoArticles() {
        let provider = NewsTimelineProvider()

        let expectation = expectation(description: "Completion called")
        provider.getSnapshot(in: .mock) { entry in
            #expect(entry.articles == nil)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    @Test("getTimeline returns empty when no articles")
    func getTimelineReturnsEmptyWhenNoArticles() {
        let provider = NewsTimelineProvider()

        let expectation = expectation(description: "Completion called")
        provider.getTimeline(in: .mock) { timeline in
            #expect(timeline.entries.count == 1)
            #expect(timeline.entries[0].articles == nil)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    @Test("getTimeline limits articles based on family")
    func getTimelineLimitsArticlesBasedOnFamily() {
        let provider = NewsTimelineProvider()

        let expectation = expectation(description: "Completion called")
        provider.getTimeline(in: .mockSmall) { timeline in
            #expect(timeline.entries.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

@Suite("PulseNewsWidget Tests")
struct PulseNewsWidgetTests {
    @Test("widget has correct kind")
    func widgetHasCorrectKind() {
        let widget = PulseNewsWidget()
        #expect(widget.kind == "PulseNewsWidget")
    }

    @Test("widget has correct configuration display name")
    func widgetHasCorrectDisplayName() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.displayName == "Top Headlines")
    }

    @Test("widget has correct description")
    func widgetHasCorrectDescription() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.description == "Stay updated with the latest news headlines.")
    }

    @Test("widget supports correct families")
    func widgetSupportsCorrectFamilies() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.supportedFamilies.contains(.systemSmall))
        #expect(widget.body.configuration.supportedFamilies.contains(.systemMedium))
        #expect(widget.body.configuration.supportedFamilies.contains(.systemLarge))
    }
}

@Suite("PulseNewsWidgetEntryView Tests")
struct PulseNewsWidgetEntryViewTests {
    @Test("entry view can be instantiated")
    func entryViewCanBeInstantiated() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemSmall
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view is PulseNewsWidgetEntryView)
    }

    @Test("headerSpacing returns correct value for small")
    func headerSpacingReturnsCorrectValueForSmall() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemSmall
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.headerSpacing == 6)
    }

    @Test("headerSpacing returns correct value for medium")
    func headerSpacingReturnsCorrectValueForMedium() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemMedium
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.headerSpacing == 8)
    }

    @Test("contentSpacing returns correct value for small")
    func contentSpacingReturnsCorrectValueForSmall() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemSmall
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.contentSpacing == 8)
    }

    @Test("contentSpacing returns correct value for medium")
    func contentSpacingReturnsCorrectValueForMedium() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemMedium
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.contentSpacing == 10)
    }

    @Test("articleLimit returns 1 for small")
    func articleLimitReturns1ForSmall() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemSmall
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.articleLimit(for: .systemSmall) == 1)
    }

    @Test("articleLimit returns 2 for medium")
    func articleLimitReturns2ForMedium() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemMedium
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.articleLimit(for: .systemMedium) == 2)
    }

    @Test("articleLimit returns 3 for large")
    func articleLimitReturns3ForLarge() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemLarge
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.articleLimit(for: .systemLarge) == 3)
    }
}

@Suite("ArticleRowView Tests")
struct ArticleRowViewTests {
    @Test("article row view can be instantiated")
    func articleRowViewCanBeInstantiated() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view is ArticleRowView)
    }

    @Test("article image shows placeholder when no image data")
    func articleImageShowsPlaceholderWhenNoImageData() {
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: nil
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view is ArticleRowView)
    }

    @Test("article image shows image when data available")
    func articleImageShowsImageWhenDataAvailable() {
        let imageData = Data(count: 100)
        let article = WidgetArticle(
            id: "1",
            title: "Test Article",
            source: "Test Source",
            imageData: imageData
        )
        let view = ArticleRowView(article: article, family: .systemSmall)
        #expect(view is ArticleRowView)
    }
}

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

// MARK: - Mock Context

extension WidgetContext {
    static var mock: WidgetContext {
        WidgetContext(family: .systemSmall)
    }

    static var mockSmall: WidgetContext {
        WidgetContext(family: .systemSmall)
    }

    static var mockMedium: WidgetContext {
        WidgetContext(family: .systemMedium)
    }

    static var mockLarge: WidgetContext {
        WidgetContext(family: .systemLarge)
    }
}
