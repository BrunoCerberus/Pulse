import Foundation
@testable import Pulse
import Testing

@Suite("SearchViewEvent Tests")
struct SearchViewEventTests {
    @Test("SearchViewEvent cases are Equatable")
    func equatable() {
        #expect(SearchViewEvent.onSearch == SearchViewEvent.onSearch)
        #expect(SearchViewEvent.onLoadMore == SearchViewEvent.onLoadMore)
        #expect(SearchViewEvent.onClear == SearchViewEvent.onClear)
        #expect(SearchViewEvent.onArticleNavigated == SearchViewEvent.onArticleNavigated)
    }

    @Test("onQueryChanged carries query string")
    func onQueryChangedCarriesValue() {
        let event1 = SearchViewEvent.onQueryChanged("test")
        let event2 = SearchViewEvent.onQueryChanged("test")
        let event3 = SearchViewEvent.onQueryChanged("other")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("onSortChanged carries sort option")
    func onSortChangedCarriesValue() {
        let event1 = SearchViewEvent.onSortChanged(.relevancy)
        let event2 = SearchViewEvent.onSortChanged(.publishedAt)

        #expect(event1 != event2)
        #expect(event1 == SearchViewEvent.onSortChanged(.relevancy))
    }

    @Test("onArticleTapped carries article ID")
    func onArticleTappedCarriesId() {
        let event1 = SearchViewEvent.onArticleTapped(articleId: "article-1")
        let event2 = SearchViewEvent.onArticleTapped(articleId: "article-1")
        let event3 = SearchViewEvent.onArticleTapped(articleId: "article-2")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("onSuggestionTapped carries suggestion string")
    func onSuggestionTappedCarriesValue() {
        let event1 = SearchViewEvent.onSuggestionTapped("swift")
        let event2 = SearchViewEvent.onSuggestionTapped("swift")
        let event3 = SearchViewEvent.onSuggestionTapped("kotlin")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("Different event types are not equal")
    func differentTypesNotEqual() {
        #expect(SearchViewEvent.onSearch != SearchViewEvent.onLoadMore)
        #expect(SearchViewEvent.onSearch != SearchViewEvent.onClear)
        #expect(SearchViewEvent.onLoadMore != SearchViewEvent.onArticleNavigated)
    }
}
