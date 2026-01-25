import Foundation

/// Events emitted by the Media view layer.
///
/// These events are mapped to domain actions via `MediaEventActionMap`
/// and dispatched to `MediaDomainInteractor`.
enum MediaViewEvent: Equatable {
    /// View appeared and should load initial data.
    case onAppear

    /// User triggered pull-to-refresh.
    case onRefresh

    /// User scrolled to bottom and should load more items.
    case onLoadMore

    /// User selected a media type filter.
    case onMediaTypeSelected(MediaType?)

    /// User tapped on a media item.
    case onMediaTapped(mediaId: String)

    /// Navigation to media detail completed.
    case onMediaNavigated

    /// User tapped the share button on a media item.
    case onShareTapped(mediaId: String)

    /// Share sheet was dismissed.
    case onShareDismissed

    /// User tapped the play button on a media item.
    case onPlayTapped(mediaId: String)

    /// Playback completed or was dismissed.
    case onPlayDismissed
}
