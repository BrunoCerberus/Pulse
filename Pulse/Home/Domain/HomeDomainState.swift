import Foundation

/// Represents the domain state for the Home feature.
///
/// This state is owned by `HomeDomainInteractor` and published via `statePublisher`.
/// ViewModels subscribe to changes and transform this state into `HomeViewState`
/// using `HomeViewStateReducer`.
struct HomeDomainState: Equatable {
    /// Breaking news articles displayed in the hero carousel.
    var breakingNews: [Article]

    /// Regular headline articles shown in the main feed with infinite scroll.
    var headlines: [Article]

    /// Indicates whether initial data is being loaded.
    var isLoading: Bool

    /// Indicates whether additional pages are being loaded (infinite scroll).
    var isLoadingMore: Bool

    /// Indicates whether a pull-to-refresh operation is in progress.
    var isRefreshing: Bool

    /// Error message to display, if any.
    var error: String?

    /// Current page number for pagination (1-indexed).
    var currentPage: Int

    /// Whether more pages are available for infinite scroll.
    var hasMorePages: Bool

    /// Whether initial data has been loaded at least once.
    var hasLoadedInitialData: Bool

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Article selected for sharing via share sheet.
    var articleToShare: Article?

    /// Currently selected category filter (nil = "All").
    var selectedCategory: NewsCategory?

    /// User's followed topics from preferences.
    var followedTopics: [NewsCategory]

    /// All available topics for the topic editor.
    var allTopics: [NewsCategory]

    /// Whether the topic editor sheet is presented.
    var isEditingTopics: Bool

    /// Whether the current error is due to being offline.
    var isOfflineError: Bool

    /// IDs of articles the user has previously read.
    var readArticleIDs: Set<String>

    /// Creates the default initial state.
    static var initial: HomeDomainState {
        HomeDomainState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false,
            selectedArticle: nil,
            articleToShare: nil,
            selectedCategory: nil,
            followedTopics: [],
            allTopics: NewsCategory.allCases,
            isEditingTopics: false,
            isOfflineError: false,
            readArticleIDs: []
        )
    }
}
