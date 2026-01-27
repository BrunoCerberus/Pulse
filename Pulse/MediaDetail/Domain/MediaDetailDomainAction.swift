import Foundation

/// Domain actions for the Media Detail feature.
///
/// These actions represent state changes triggered by user interactions
/// or playback events from the audio/video player.
enum MediaDetailDomainAction: Equatable {
    // MARK: - Lifecycle

    /// View appeared, initialize state.
    case onAppear

    // MARK: - Playback Control

    /// Start or resume playback.
    case play

    /// Pause playback.
    case pause

    /// Seek to a position (0.0 - 1.0).
    case seek(progress: Double)

    /// Skip backward by specified seconds.
    case skipBackward(seconds: Double)

    /// Skip forward by specified seconds.
    case skipForward(seconds: Double)

    // MARK: - Playback Events

    /// Playback progress updated from player.
    case playbackProgressUpdated(progress: Double, currentTime: TimeInterval)

    /// Duration loaded from player.
    case durationLoaded(TimeInterval)

    /// Player started loading.
    case playerLoading

    /// Player finished loading and is ready.
    case playerReady

    /// Playback error occurred.
    case playbackError(String)

    // MARK: - Share Sheet

    /// Show share sheet.
    case showShareSheet

    /// Dismiss share sheet.
    case dismissShareSheet

    // MARK: - Bookmark

    /// Toggle bookmark status.
    case toggleBookmark

    /// Bookmark status loaded from storage.
    case bookmarkStatusLoaded(Bool)

    // MARK: - Browser

    /// Open the original media URL in browser.
    case openInBrowser
}
