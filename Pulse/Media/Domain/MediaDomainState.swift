import Foundation

/// Represents the domain state for the Media feature.
///
/// This state is owned by `MediaDomainInteractor` and published via `statePublisher`.
/// ViewModels subscribe to changes and transform this state into `MediaViewState`
/// using `MediaViewStateReducer`.
struct MediaDomainState: Equatable {
    /// Currently selected media type filter (nil = all media).
    var selectedType: MediaType?

    /// Featured media items displayed in the hero carousel.
    var featuredMedia: [Article]

    /// Regular media items shown in the main feed with infinite scroll.
    var mediaItems: [Article]

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

    /// Media item selected for navigation to detail view.
    var selectedMedia: Article?

    /// Media item selected for sharing via share sheet.
    var mediaToShare: Article?

    /// Media item selected for playback.
    var mediaToPlay: Article?

    /// Creates the default initial state.
    static var initial: MediaDomainState {
        MediaDomainState(
            selectedType: nil,
            featuredMedia: [],
            mediaItems: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false,
            selectedMedia: nil,
            mediaToShare: nil,
            mediaToPlay: nil
        )
    }
}
