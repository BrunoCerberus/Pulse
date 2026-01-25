import Foundation

/// Represents the domain state for the Media Detail feature.
///
/// This state is owned by `MediaDetailDomainInteractor` and published via `statePublisher`.
/// The media detail view displays videos (via WKWebView) or podcasts (via AVPlayer).
struct MediaDetailDomainState: Equatable {
    /// The media article being displayed.
    let article: Article

    // MARK: - Playback State

    /// Whether media is currently playing.
    var isPlaying: Bool

    /// Playback progress from 0.0 to 1.0.
    var playbackProgress: Double

    /// Current playback time in seconds.
    var currentTime: TimeInterval

    /// Total duration in seconds.
    var duration: TimeInterval

    // MARK: - Loading State

    /// Whether the player is loading.
    var isLoading: Bool

    /// Error message if playback failed.
    var error: String?

    // MARK: - UI State

    /// Whether to show the native share sheet.
    var showShareSheet: Bool

    /// Whether the article is bookmarked by the user.
    var isBookmarked: Bool

    /// Creates the initial state for a given media article.
    /// - Parameter article: The media article to display.
    /// - Returns: Initial state with loading in progress.
    static func initial(article: Article) -> MediaDetailDomainState {
        MediaDetailDomainState(
            article: article,
            isPlaying: false,
            playbackProgress: 0,
            currentTime: 0,
            duration: 0,
            isLoading: true,
            error: nil,
            showShareSheet: false,
            isBookmarked: false
        )
    }
}
