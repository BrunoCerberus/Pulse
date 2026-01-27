import Foundation
@testable import Pulse
import Testing

@Suite("SearchDomainState Tests")
struct SearchDomainStateTests {
    private var testArticles: [Article] {
        [
            Article(
                id: "article-1",
                title: "Article 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: Date()
            ),
        ]
    }

    @Test("Initial state has correct default values")
    func initialState() {
        let state = SearchDomainState.initial

        #expect(state.query == "")
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.isLoadingMore == false)
        #expect(state.isSorting == false)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages == true)
        #expect(state.sortBy == .relevancy)
        #expect(state.hasSearched == false)
        #expect(state.selectedArticle == nil)
    }

    @Test("Query can be set")
    func queryCanBeSet() {
        var state = SearchDomainState.initial
        state.query = "Swift"
        #expect(state.query == "Swift")
    }

    @Test("Results can be set")
    func resultsCanBeSet() {
        var state = SearchDomainState.initial
        state.results = testArticles
        #expect(state.results.count == 1)
    }

    @Test("Suggestions can be set")
    func suggestionsCanBeSet() {
        var state = SearchDomainState.initial
        state.suggestions = ["Swift", "SwiftUI"]
        #expect(state.suggestions.count == 2)
    }

    @Test("Sort by can be changed")
    func sortByCanBeChanged() {
        var state = SearchDomainState.initial

        state.sortBy = .publishedAt
        #expect(state.sortBy == .publishedAt)

        state.sortBy = .popularity
        #expect(state.sortBy == .popularity)
    }

    @Test("Has searched can be set")
    func hasSearchedCanBeSet() {
        var state = SearchDomainState.initial
        state.hasSearched = true
        #expect(state.hasSearched == true)
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = SearchDomainState.initial
        let state2 = SearchDomainState.initial
        #expect(state1 == state2)
    }

    @Test("States with different values are not equal")
    func differentValuesAreNotEqual() {
        let state1 = SearchDomainState.initial
        var state2 = SearchDomainState.initial
        state2.query = "test"

        #expect(state1 != state2)
    }
}

@Suite("SearchSortOption Tests")
struct SearchSortOptionTests {
    @Test("All cases exist")
    func allCases() {
        let allCases = SearchSortOption.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.relevancy))
        #expect(allCases.contains(.publishedAt))
        #expect(allCases.contains(.popularity))
    }

    @Test("Raw values are correct")
    func rawValues() {
        #expect(SearchSortOption.relevancy.rawValue == "relevancy")
        #expect(SearchSortOption.publishedAt.rawValue == "publishedAt")
        #expect(SearchSortOption.popularity.rawValue == "popularity")
    }

    @Test("IDs match raw values")
    func ids() {
        #expect(SearchSortOption.relevancy.id == "relevancy")
        #expect(SearchSortOption.publishedAt.id == "publishedAt")
        #expect(SearchSortOption.popularity.id == "popularity")
    }

    @Test("Display names are correct")
    func displayNames() {
        #expect(SearchSortOption.relevancy.displayName == "Relevance")
        #expect(SearchSortOption.publishedAt.displayName == "Date")
        #expect(SearchSortOption.popularity.displayName == "Popularity")
    }
}
