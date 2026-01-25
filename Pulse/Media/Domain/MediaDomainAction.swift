import Foundation

/// Actions that can be dispatched to the Media domain interactor.
enum MediaDomainAction: Equatable {
    /// Load initial data (featured media and first page of media items).
    case loadInitialData

    /// Load the next page of media items (infinite scroll).
    case loadMoreMedia

    /// Refresh all data (pull-to-refresh).
    case refresh

    /// Filter by media type (nil = all types).
    case selectMediaType(MediaType?)

    /// Select a media item for navigation to detail view.
    case selectMedia(mediaId: String)

    /// Clear the selected media item after navigation completes.
    case clearSelectedMedia

    /// Select a media item for sharing.
    case shareMedia(mediaId: String)

    /// Clear the media item selected for sharing.
    case clearMediaToShare

    /// Play a media item (opens in external player).
    case playMedia(mediaId: String)

    /// Clear the media item selected for playback.
    case clearMediaToPlay
}
