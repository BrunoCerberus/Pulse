import Foundation

/// View events that can be triggered from the Media Detail screen.
enum MediaDetailViewEvent: Equatable {
    // MARK: - Lifecycle

    /// View appeared.
    case onAppear

    // MARK: - Playback Control

    /// Play/Pause button tapped.
    case onPlayPauseTapped

    /// User seeks to a position (0.0 - 1.0).
    case onSeek(progress: Double)

    /// Skip backward button tapped (-15s).
    case onSkipBackwardTapped

    /// Skip forward button tapped (+30s).
    case onSkipForwardTapped

    // MARK: - Playback Events (from player)

    /// Progress update from player.
    case onProgressUpdate(progress: Double, currentTime: TimeInterval)

    /// Duration loaded from player.
    case onDurationLoaded(TimeInterval)

    /// Player started loading.
    case onPlayerLoading

    /// Player finished loading.
    case onPlayerReady

    /// Playback error occurred.
    case onError(String)

    // MARK: - Actions

    /// Share button tapped.
    case onShareTapped

    /// Share sheet dismissed.
    case onShareDismissed

    /// Bookmark button tapped.
    case onBookmarkTapped

    /// Open in browser button tapped.
    case onOpenInBrowserTapped
}
