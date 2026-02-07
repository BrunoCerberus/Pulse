import SwiftUI
import WidgetKit
import Testing

@Suite("PulseNewsWidgetEntryView Tests")
struct PulseNewsWidgetEntryViewTests {
    @Test("entry view stores correct family")
    func entryViewStoresCorrectFamily() {
        let entry = NewsTimelineEntry(
            date: Date(),
            articles: nil,
            family: .systemSmall
        )
        let view = PulseNewsWidgetEntryView(entry: entry)
        #expect(view.entry.family == .systemSmall)
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
