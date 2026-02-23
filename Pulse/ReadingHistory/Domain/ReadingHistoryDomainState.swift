import Foundation

/// Represents the domain state for the Reading History feature.
///
/// This state is owned by `ReadingHistoryDomainInteractor` and published via `statePublisher`.
struct ReadingHistoryDomainState: Equatable {
    /// All read articles, ordered by read date (newest first).
    var articles: [Article]

    /// Indicates whether history is being loaded.
    var isLoading: Bool

    /// Error message to display, if any.
    var error: String?

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Creates the default initial state.
    static var initial: ReadingHistoryDomainState {
        ReadingHistoryDomainState(
            articles: [],
            isLoading: false,
            error: nil,
            selectedArticle: nil
        )
    }
}
