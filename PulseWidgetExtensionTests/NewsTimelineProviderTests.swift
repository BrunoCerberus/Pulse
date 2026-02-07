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
