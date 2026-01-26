import Foundation

/// View state for the Media feature.
///
/// This state is computed from `MediaDomainState` via `MediaViewStateReducer`
/// and consumed directly by the SwiftUI view layer.
struct MediaViewState: Equatable {
    /// Currently selected media type filter (nil = all types).
    var selectedType: MediaType?

    /// Featured media items for the hero carousel.
    var featuredMedia: [MediaViewItem]

    /// Media items for the main feed with infinite scroll.
    var mediaItems: [MediaViewItem]

    /// Indicates whether initial data is being loaded.
    var isLoading: Bool

    /// Indicates whether additional pages are being loaded (infinite scroll).
    var isLoadingMore: Bool

    /// Indicates whether a pull-to-refresh operation is in progress.
    var isRefreshing: Bool

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether to show the empty state view.
    var showEmptyState: Bool

    /// Media item selected for navigation to detail view.
    var selectedMedia: Article?

    /// Media item selected for sharing via share sheet.
    var mediaToShare: Article?

    /// Media item selected for playback.
    var mediaToPlay: Article?

    /// Creates the default initial state.
    static var initial: MediaViewState {
        MediaViewState(
            selectedType: nil,
            featuredMedia: [],
            mediaItems: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedMedia: nil,
            mediaToShare: nil,
            mediaToPlay: nil
        )
    }
}

/// View model for a single media item.
///
/// Contains pre-formatted data optimized for display in the view layer.
struct MediaViewItem: Identifiable, Equatable {
    /// Unique identifier for the media item.
    let id: String

    /// Title of the media content.
    let title: String

    /// Brief description of the content.
    let description: String?

    /// Name of the source (podcast name, YouTube channel, etc.).
    let sourceName: String

    /// Thumbnail image URL for list cells.
    let imageURL: URL?

    /// High-resolution image URL for featured/hero display.
    let heroImageURL: URL?

    /// Relative formatted date (e.g., "2h ago").
    let formattedDate: String

    /// Formatted duration string (e.g., "1:23:45").
    let formattedDuration: String?

    /// Type of media (video or podcast).
    let mediaType: MediaType?

    /// Direct URL to the media content for playback.
    let mediaURL: String?

    /// Full article URL for sharing.
    let url: String

    /// Pre-computed index for staggered animations.
    let animationIndex: Int

    /// Creates a view item from an Article model.
    /// - Parameters:
    ///   - article: The source article.
    ///   - index: Index for staggered animation delay calculation.
    init(from article: Article, index: Int = 0) {
        id = article.id
        title = article.title
        description = article.description
        sourceName = article.source.name
        imageURL = article.displayImageURL.flatMap { URL(string: $0) }
        heroImageURL = article.heroImageURL.flatMap { URL(string: $0) }
        formattedDate = article.formattedDate
        formattedDuration = article.formattedDuration
        mediaType = article.mediaType
        mediaURL = article.mediaURL
        url = article.url
        animationIndex = index
    }
}
