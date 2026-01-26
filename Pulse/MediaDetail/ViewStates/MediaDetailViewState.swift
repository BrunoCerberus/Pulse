import Foundation

/// View state for the Media Detail screen.
struct MediaDetailViewState: Equatable {
    /// The media article being displayed.
    let article: Article

    /// Whether media is currently playing.
    var isPlaying: Bool

    /// Playback progress from 0.0 to 1.0.
    var playbackProgress: Double

    /// Formatted current time (e.g., "1:23" or "1:23:45").
    var currentTimeFormatted: String

    /// Formatted duration (e.g., "5:45" or "1:23:45").
    var durationFormatted: String

    /// Whether the player is loading.
    var isLoading: Bool

    /// Error message if playback failed.
    var errorMessage: String?

    /// Whether to show the native share sheet.
    var showShareSheet: Bool

    /// Whether the article is bookmarked.
    var isBookmarked: Bool

    /// Creates the initial state for a given media article.
    static func initial(article: Article) -> MediaDetailViewState {
        MediaDetailViewState(
            article: article,
            isPlaying: false,
            playbackProgress: 0,
            currentTimeFormatted: "0:00",
            durationFormatted: article.formattedDuration ?? "0:00",
            isLoading: true,
            errorMessage: nil,
            showShareSheet: false,
            isBookmarked: false
        )
    }
}
