import Foundation

/// Represents the domain state for the Search feature.
///
/// This state is owned by `SearchDomainInteractor` and published via `statePublisher`.
/// ViewModels subscribe to changes and transform this state into `SearchViewState`
/// using `SearchViewStateReducer`.
struct SearchDomainState: Equatable {
    /// Current search query entered by the user.
    var query: String

    /// Search results matching the current query.
    var results: [Article]

    /// Autocomplete suggestions for the current query.
    var suggestions: [String]

    /// Indicates whether a search is in progress.
    var isLoading: Bool

    /// Indicates whether additional pages are being loaded (infinite scroll).
    var isLoadingMore: Bool

    /// Indicates whether results are being re-sorted.
    var isSorting: Bool

    /// Error message to display, if any.
    var error: String?

    /// Current page number for pagination (1-indexed).
    var currentPage: Int

    /// Whether more pages are available for infinite scroll.
    var hasMorePages: Bool

    /// Current sort order for search results.
    var sortBy: SearchSortOption

    /// Whether a search has been performed at least once.
    var hasSearched: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Whether the current error is due to being offline.
    var isOfflineError: Bool

    /// Creates the default initial state.
    static var initial: SearchDomainState {
        SearchDomainState(
            query: "",
            results: [],
            suggestions: [],
            isLoading: false,
            isLoadingMore: false,
            isSorting: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            sortBy: .relevancy,
            hasSearched: false,
            selectedArticle: nil,
            isOfflineError: false
        )
    }
}

/// Sort options for search results.
enum SearchSortOption: String, CaseIterable, Identifiable {
    /// Sort by search relevance (default).
    case relevancy

    /// Sort by publication date (newest first).
    case publishedAt

    /// Sort by popularity/engagement.
    case popularity

    var id: String {
        rawValue
    }

    /// Human-readable display name for the sort option.
    var displayName: String {
        switch self {
        case .relevancy: return String(localized: "search.sort.relevance")
        case .publishedAt: return String(localized: "search.sort.date")
        case .popularity: return String(localized: "search.sort.popularity")
        }
    }
}
