import Foundation

/// View state for the Search screen.
///
/// This state is computed from `SearchDomainState` and consumed directly
/// by the SwiftUI view layer.
struct SearchViewState: Equatable {
    /// Current search query text entered by the user.
    var query: String

    /// Search results as article view items.
    var results: [ArticleViewItem]

    /// Search suggestions based on popular or recent queries.
    var suggestions: [String]

    /// Indicates whether the initial search is in progress.
    var isLoading: Bool

    /// Indicates whether additional result pages are being loaded (infinite scroll).
    var isLoadingMore: Bool

    /// Indicates whether results are being re-sorted.
    var isSorting: Bool

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether to show the "no results" state (search executed but nothing found).
    var showNoResults: Bool

    /// Whether at least one search has been executed (differentiates initial state from no results).
    var hasSearched: Bool

    /// Current sort option for ordering results.
    var sortOption: SearchSortOption

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Whether the current error is due to being offline.
    var isOfflineError: Bool

    /// Creates the default initial state with empty query and results.
    static var initial: SearchViewState {
        SearchViewState(
            query: "",
            results: [],
            suggestions: [],
            isLoading: false,
            isLoadingMore: false,
            isSorting: false,
            errorMessage: nil,
            showNoResults: false,
            hasSearched: false,
            sortOption: .relevancy,
            selectedArticle: nil,
            isOfflineError: false
        )
    }
}
