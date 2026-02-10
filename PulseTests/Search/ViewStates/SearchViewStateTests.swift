import Foundation
@testable import Pulse
import Testing

@Suite("SearchViewState Tests")
struct SearchViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = SearchViewState.initial

        #expect(state.query == "")
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isSorting)
        #expect(state.errorMessage == nil)
        #expect(!state.showNoResults)
        #expect(!state.hasSearched)
        #expect(state.sortOption == .relevancy)
        #expect(state.selectedArticle == nil)
    }

    @Test("SearchViewState is Equatable")
    func equatable() {
        let state1 = SearchViewState.initial
        let state2 = SearchViewState.initial

        #expect(state1 == state2)
    }

    @Test("SearchViewState with different values are not equal")
    func notEqual() {
        var state1 = SearchViewState.initial
        var state2 = SearchViewState.initial

        state1.query = "test"
        #expect(state1 != state2)

        state2.query = "test"
        state1.isLoading = true
        #expect(state1 != state2)
    }
}
