import Foundation
@testable import Pulse
import Testing

@Suite("SearchSortOption Enum Tests")
struct SearchSortOptionEnumTests {
    @Test("Can create relevancy sort option")
    func relevancySortOption() {
        let option = SearchSortOption.relevancy
        #expect(option == .relevancy)
        #expect(option.displayName == "Relevancy")
    }

    @Test("Can create publishedAt sort option")
    func publishedAtSortOption() {
        let option = SearchSortOption.publishedAt
        #expect(option == .publishedAt)
        #expect(option.displayName == "Newest")
    }

    @Test("Can create popularity sort option")
    func popularitySortOption() {
        let option = SearchSortOption.popularity
        #expect(option == .popularity)
        #expect(option.displayName == "Popularity")
    }

    @Test("All sort options are in CaseIterable")
    func allSortOptionsAvailable() {
        let allOptions = SearchSortOption.allCases
        #expect(allOptions.count == 3)
    }

    @Test("Sort options have Identifiable conformance")
    func sortOptionsIdentifiable() {
        let option1 = SearchSortOption.relevancy
        let option2 = SearchSortOption.publishedAt
        #expect(option1.id != option2.id)
    }

    @Test("Sort option rawValues are correct")
    func sortOptionRawValues() {
        #expect(SearchSortOption.relevancy.rawValue == "relevancy")
        #expect(SearchSortOption.publishedAt.rawValue == "publishedAt")
        #expect(SearchSortOption.popularity.rawValue == "popularity")
    }
}

@Suite("SearchDomainState Initialization Tests")
struct SearchDomainStateInitializationTests {
    @Test("Initial query is empty")
    func initialQueryEmpty() {
        let state = SearchDomainState()
        #expect(state.query.isEmpty)
    }

    @Test("Initial results are empty")
    func initialResultsEmpty() {
        let state = SearchDomainState()
        #expect(state.results.isEmpty)
    }

    @Test("Initial suggestions are empty")
    func initialSuggestionsEmpty() {
        let state = SearchDomainState()
        #expect(state.suggestions.isEmpty)
    }

    @Test("Initial loading flags are false")
    func initialLoadingFalse() {
        let state = SearchDomainState()
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isSorting)
    }

    @Test("Initial error is nil")
    func initialErrorNil() {
        let state = SearchDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial page is 1")
    func initialPageOne() {
        let state = SearchDomainState()
        #expect(state.currentPage == 1)
    }

    @Test("Initial hasMorePages is true")
    func initialHasMorePages() {
        let state = SearchDomainState()
        #expect(state.hasMorePages)
    }

    @Test("Initial sort option is relevancy")
    func initialSortOptionRelevancy() {
        let state = SearchDomainState()
        #expect(state.sortBy == .relevancy)
    }

    @Test("Initial hasSearched is false")
    func initialHasSearchedFalse() {
        let state = SearchDomainState()
        #expect(!state.hasSearched)
    }

    @Test("Initial selectedArticle is nil")
    func initialSelectedArticleNil() {
        let state = SearchDomainState()
        #expect(state.selectedArticle == nil)
    }
}

@Suite("SearchDomainState Query Tests")
struct SearchDomainStateQueryTests {
    @Test("Can set search query")
    func setQuery() {
        var state = SearchDomainState()
        state.query = "Swift"
        #expect(state.query == "Swift")
    }

    @Test("Can change search query")
    func changeQuery() {
        var state = SearchDomainState()
        state.query = "Swift"
        state.query = "iOS"
        #expect(state.query == "iOS")
    }

    @Test("Can clear search query")
    func clearQuery() {
        var state = SearchDomainState()
        state.query = "Query"
        state.query = ""
        #expect(state.query.isEmpty)
    }

    @Test("Query supports special characters")
    func queryWithSpecialCharacters() {
        var state = SearchDomainState()
        state.query = "Swift & iOS (18+)"
        #expect(state.query == "Swift & iOS (18+)")
    }
}

@Suite("SearchDomainState Results Tests")
struct SearchDomainStateResultsTests {
    @Test("Can set search results")
    func setResults() {
        var state = SearchDomainState()
        let articles = Array(Article.mockArticles.prefix(5))
        state.results = articles
        #expect(state.results.count == 5)
    }

    @Test("Can append results for pagination")
    func appendResults() {
        var state = SearchDomainState()
        state.results = Array(Article.mockArticles.prefix(3))
        state.results.append(contentsOf: Array(Article.mockArticles.suffix(2)))
        #expect(state.results.count == 5)
    }

    @Test("Can clear results")
    func clearResults() {
        var state = SearchDomainState()
        state.results = Article.mockArticles
        state.results = []
        #expect(state.results.isEmpty)
    }

    @Test("Results persist across query changes")
    func resultsPersistAcrossQueryChanges() {
        var state = SearchDomainState()
        state.results = Array(Article.mockArticles.prefix(3))
        state.query = "New query"
        #expect(state.results.count == 3)
    }
}

@Suite("SearchDomainState Suggestions Tests")
struct SearchDomainStateSuggestionsTests {
    @Test("Can set search suggestions")
    func setSuggestions() {
        var state = SearchDomainState()
        state.suggestions = ["Swift", "iOS", "SwiftUI"]
        #expect(state.suggestions.count == 3)
    }

    @Test("Can append suggestions")
    func appendSuggestions() {
        var state = SearchDomainState()
        state.suggestions = ["Swift"]
        state.suggestions.append("iOS")
        #expect(state.suggestions.count == 2)
    }

    @Test("Can clear suggestions")
    func clearSuggestions() {
        var state = SearchDomainState()
        state.suggestions = ["Swift", "iOS"]
        state.suggestions = []
        #expect(state.suggestions.isEmpty)
    }

    @Test("Suggestions are independent from results")
    func suggestionsIndependentFromResults() {
        var state = SearchDomainState()
        state.suggestions = ["Suggested 1", "Suggested 2"]
        state.results = Array(Article.mockArticles.prefix(5))
        #expect(state.suggestions.count == 2)
        #expect(state.results.count == 5)
    }
}

@Suite("SearchDomainState Loading States Tests")
struct SearchDomainStateLoadingStatesTests {
    @Test("Can set isLoading flag")
    func setIsLoading() {
        var state = SearchDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can set isLoadingMore flag")
    func setIsLoadingMore() {
        var state = SearchDomainState()
        state.isLoadingMore = true
        #expect(state.isLoadingMore)
    }

    @Test("Can set isSorting flag")
    func setIsSorting() {
        var state = SearchDomainState()
        state.isSorting = true
        #expect(state.isSorting)
    }

    @Test("Loading flags are independent")
    func loadingFlagsIndependent() {
        var state = SearchDomainState()
        state.isLoading = true
        state.isLoadingMore = true
        #expect(state.isLoading)
        #expect(state.isLoadingMore)
        #expect(!state.isSorting)
    }

    @Test("Can toggle all loading flags")
    func toggleAllLoadingFlags() {
        var state = SearchDomainState()
        state.isLoading = true
        state.isLoadingMore = true
        state.isSorting = true
        #expect(state.isLoading && state.isLoadingMore && state.isSorting)

        state.isLoading = false
        state.isLoadingMore = false
        state.isSorting = false
        #expect(!state.isLoading && !state.isLoadingMore && !state.isSorting)
    }
}

@Suite("SearchDomainState Error Tests")
struct SearchDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = SearchDomainState()
        state.error = "Search failed"
        #expect(state.error == "Search failed")
    }

    @Test("Can clear error")
    func clearError() {
        var state = SearchDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }
}

@Suite("SearchDomainState Pagination Tests")
struct SearchDomainStatePaginationTests {
    @Test("Can increment current page")
    func incrementPage() {
        var state = SearchDomainState()
        state.currentPage = 2
        #expect(state.currentPage == 2)
    }

    @Test("Can set arbitrary page number")
    func setArbitraryPage() {
        var state = SearchDomainState()
        state.currentPage = 10
        #expect(state.currentPage == 10)
    }

    @Test("Can set hasMorePages flag")
    func setHasMorePages() {
        var state = SearchDomainState()
        state.hasMorePages = false
        #expect(!state.hasMorePages)
    }

    @Test("Current page and hasMorePages are independent")
    func pageAndHasMorePagesIndependent() {
        var state = SearchDomainState()
        state.currentPage = 5
        state.hasMorePages = false
        #expect(state.currentPage == 5)
        #expect(!state.hasMorePages)
    }
}

@Suite("SearchDomainState Sort Option Tests")
struct SearchDomainStateSortOptionTests {
    @Test("Can change sort option to publishedAt")
    func changeSortToPublishedAt() {
        var state = SearchDomainState()
        state.sortBy = .publishedAt
        #expect(state.sortBy == .publishedAt)
    }

    @Test("Can change sort option to popularity")
    func changeSortToPopularity() {
        var state = SearchDomainState()
        state.sortBy = .popularity
        #expect(state.sortBy == .popularity)
    }

    @Test("Can cycle through all sort options")
    func cycleThroughSortOptions() {
        var state = SearchDomainState()
        for option in SearchSortOption.allCases {
            state.sortBy = option
            #expect(state.sortBy == option)
        }
    }
}

@Suite("SearchDomainState Search Status Tests")
struct SearchDomainStateSearchStatusTests {
    @Test("Can set hasSearched flag")
    func setHasSearched() {
        var state = SearchDomainState()
        state.hasSearched = true
        #expect(state.hasSearched)
    }

    @Test("hasSearched persists through state changes")
    func hasSearchedPersists() {
        var state = SearchDomainState()
        state.hasSearched = true
        state.query = "New query"
        state.results = Array(Article.mockArticles.prefix(3))
        #expect(state.hasSearched)
    }

    @Test("hasSearched independent from results")
    func hasSearchedIndependentFromResults() {
        var state = SearchDomainState()
        state.hasSearched = true
        state.results = []
        #expect(state.hasSearched)
        #expect(state.results.isEmpty)
    }
}

@Suite("SearchDomainState Article Selection Tests")
struct SearchDomainStateArticleSelectionTests {
    @Test("Can set selected article")
    func setSelectedArticle() {
        var state = SearchDomainState()
        let article = Article.mockArticles[0]
        state.selectedArticle = article
        #expect(state.selectedArticle == article)
    }

    @Test("Can clear selected article")
    func clearSelectedArticle() {
        var state = SearchDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    @Test("Can change selected article")
    func changeSelectedArticle() {
        var state = SearchDomainState()
        state.selectedArticle = Article.mockArticles[0]
        state.selectedArticle = Article.mockArticles[1]
        #expect(state.selectedArticle == Article.mockArticles[1])
    }
}

@Suite("SearchDomainState Equatable Tests")
struct SearchDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = SearchDomainState()
        let state2 = SearchDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different queries are not equal")
    func differentQueryNotEqual() {
        var state1 = SearchDomainState()
        var state2 = SearchDomainState()
        state1.query = "Swift"
        #expect(state1 != state2)
    }

    @Test("States with different results are not equal")
    func differentResultsNotEqual() {
        var state1 = SearchDomainState()
        var state2 = SearchDomainState()
        state1.results = Array(Article.mockArticles.prefix(1))
        #expect(state1 != state2)
    }

    @Test("States with different sort options are not equal")
    func differentSortOptionNotEqual() {
        var state1 = SearchDomainState()
        var state2 = SearchDomainState()
        state1.sortBy = .popularity
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = SearchDomainState()
        var state2 = SearchDomainState()
        state1.query = "iOS"
        state2.query = "iOS"
        #expect(state1 == state2)
    }
}

@Suite("SearchDomainState Complex Search Scenarios")
struct SearchDomainStateComplexSearchScenarioTests {
    @Test("Simulate complete search workflow")
    func completeSearchWorkflow() {
        var state = SearchDomainState()
        #expect(state.query.isEmpty)
        #expect(!state.hasSearched)

        // User types query
        state.query = "Swift"
        state.isLoading = true
        state.suggestions = ["Swift 5.0", "Swift 5.9", "SwiftUI"]

        // Results return
        state.results = Array(Article.mockArticles.prefix(10))
        state.isLoading = false
        state.hasSearched = true

        #expect(state.hasSearched)
        #expect(state.results.count == 10)
        #expect(!state.isLoading)
    }

    @Test("Simulate search with sorting")
    func searchWithSorting() {
        var state = SearchDomainState()
        state.query = "iOS"
        state.results = Array(Article.mockArticles.prefix(5))

        state.isSorting = true
        state.sortBy = .publishedAt
        state.results = Array(Article.mockArticles.prefix(5)).reversed()
        state.isSorting = false

        #expect(state.sortBy == .publishedAt)
        #expect(!state.isSorting)
    }

    @Test("Simulate pagination in search results")
    func paginationInSearchResults() {
        var state = SearchDomainState()
        state.query = "Test"
        state.results = Array(Article.mockArticles.prefix(10))
        state.currentPage = 1

        state.isLoadingMore = true
        state.currentPage = 2
        state.results.append(contentsOf: Array(Article.mockArticles.prefix(10)))
        state.isLoadingMore = false

        #expect(state.currentPage == 2)
        #expect(state.results.count == 20)
    }

    @Test("Simulate search with no results")
    func searchWithNoResults() {
        var state = SearchDomainState()
        state.query = "nonexistent"
        state.isLoading = true
        state.results = []
        state.isLoading = false
        state.hasSearched = true

        #expect(state.hasSearched)
        #expect(state.results.isEmpty)
        #expect(state.query == "nonexistent")
    }

    @Test("Simulate search error handling")
    func searchErrorHandling() {
        var state = SearchDomainState()
        state.query = "Test"
        state.isLoading = true
        state.error = "Network error"
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.error == "Network error")
    }
}
