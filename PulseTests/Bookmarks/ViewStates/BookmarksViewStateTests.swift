import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksViewState Tests")
struct BookmarksViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = BookmarksViewState.initial

        #expect(state.bookmarks.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(state.selectedArticle == nil)
    }

    @Test("BookmarksViewState is Equatable")
    func equatable() {
        let state1 = BookmarksViewState.initial
        let state2 = BookmarksViewState.initial

        #expect(state1 == state2)
    }

    @Test("Modified state is not equal to initial")
    func modifiedNotEqual() {
        var state = BookmarksViewState.initial
        state.isLoading = true

        #expect(state != BookmarksViewState.initial)
    }
}

@Suite("BookmarksViewEvent Tests")
struct BookmarksViewEventTests {
    @Test("BookmarksViewEvent cases are Equatable")
    func equatable() {
        #expect(BookmarksViewEvent.onAppear == BookmarksViewEvent.onAppear)
        #expect(BookmarksViewEvent.onRefresh == BookmarksViewEvent.onRefresh)
        #expect(BookmarksViewEvent.onArticleNavigated == BookmarksViewEvent.onArticleNavigated)
    }

    @Test("onArticleTapped carries article ID")
    func onArticleTappedCarriesId() {
        let event1 = BookmarksViewEvent.onArticleTapped(articleId: "id-1")
        let event2 = BookmarksViewEvent.onArticleTapped(articleId: "id-1")
        let event3 = BookmarksViewEvent.onArticleTapped(articleId: "id-2")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("onRemoveBookmark carries article ID")
    func onRemoveBookmarkCarriesId() {
        let event1 = BookmarksViewEvent.onRemoveBookmark(articleId: "id-1")
        let event2 = BookmarksViewEvent.onRemoveBookmark(articleId: "id-1")
        let event3 = BookmarksViewEvent.onRemoveBookmark(articleId: "id-2")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("Different event types are not equal")
    func differentTypesNotEqual() {
        #expect(BookmarksViewEvent.onAppear != BookmarksViewEvent.onRefresh)
        #expect(BookmarksViewEvent.onRefresh != BookmarksViewEvent.onArticleNavigated)
    }
}
