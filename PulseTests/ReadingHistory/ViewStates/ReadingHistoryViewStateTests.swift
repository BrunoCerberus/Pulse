import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryViewState Tests")
struct ReadingHistoryViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = ReadingHistoryViewState.initial

        #expect(state.articles.isEmpty)
        #expect(!state.isLoading)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(state.selectedArticle == nil)
    }

    @Test("ReadingHistoryViewState is Equatable")
    func equatable() {
        let state1 = ReadingHistoryViewState.initial
        let state2 = ReadingHistoryViewState.initial

        #expect(state1 == state2)
    }

    @Test("Modified state is not equal to initial")
    func modifiedNotEqual() {
        var state = ReadingHistoryViewState.initial
        state.isLoading = true

        #expect(state != ReadingHistoryViewState.initial)
    }
}

@Suite("ReadingHistoryViewEvent Tests")
struct ReadingHistoryViewEventTests {
    @Test("ReadingHistoryViewEvent cases are Equatable")
    func equatable() {
        #expect(ReadingHistoryViewEvent.onAppear == ReadingHistoryViewEvent.onAppear)
        #expect(ReadingHistoryViewEvent.onClearHistoryTapped == ReadingHistoryViewEvent.onClearHistoryTapped)
        #expect(ReadingHistoryViewEvent.onArticleNavigated == ReadingHistoryViewEvent.onArticleNavigated)
    }

    @Test("onArticleTapped carries article ID")
    func onArticleTappedCarriesId() {
        let event1 = ReadingHistoryViewEvent.onArticleTapped(articleId: "id-1")
        let event2 = ReadingHistoryViewEvent.onArticleTapped(articleId: "id-1")
        let event3 = ReadingHistoryViewEvent.onArticleTapped(articleId: "id-2")

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("Different event types are not equal")
    func differentTypesNotEqual() {
        #expect(ReadingHistoryViewEvent.onAppear != ReadingHistoryViewEvent.onClearHistoryTapped)
        #expect(ReadingHistoryViewEvent.onClearHistoryTapped != ReadingHistoryViewEvent.onArticleNavigated)
        #expect(ReadingHistoryViewEvent.onAppear != ReadingHistoryViewEvent.onArticleNavigated)
    }
}
