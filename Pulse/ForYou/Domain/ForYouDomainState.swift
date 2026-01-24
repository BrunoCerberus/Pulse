import Foundation

/// Represents the domain state for the For You (personalized feed) feature.
///
/// This state is owned by `ForYouDomainInteractor` and published via `statePublisher`.
/// The For You feature provides personalized article recommendations based on
/// the user's followed topics and preferences.
///
/// - Note: This is a **Premium** feature.
struct ForYouDomainState: Equatable {
    /// Personalized articles matching the user's preferences.
    var articles: [Article]

    /// User's current preferences including followed topics.
    var preferences: UserPreferences

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

    /// Creates the default initial state.
    static var initial: ForYouDomainState {
        ForYouDomainState(
            articles: [],
            preferences: .default,
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )
    }
}
