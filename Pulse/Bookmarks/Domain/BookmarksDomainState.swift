import Foundation

/// Represents the domain state for the Bookmarks feature.
///
/// This state is owned by `BookmarksDomainInteractor` and published via `statePublisher`.
/// Bookmarks are persisted locally using SwiftData for offline reading.
struct BookmarksDomainState: Equatable {
    /// All bookmarked articles, ordered by bookmark date (newest first).
    var bookmarks: [Article]

    /// Indicates whether bookmarks are being loaded.
    var isLoading: Bool

    /// Indicates whether a pull-to-refresh operation is in progress.
    var isRefreshing: Bool

    /// Error message to display, if any.
    var error: String?

    /// Article selected for navigation to detail view.
    var selectedArticle: Article?

    /// Creates the default initial state.
    static var initial: BookmarksDomainState {
        BookmarksDomainState(
            bookmarks: [],
            isLoading: false,
            isRefreshing: false,
            error: nil,
            selectedArticle: nil
        )
    }
}
