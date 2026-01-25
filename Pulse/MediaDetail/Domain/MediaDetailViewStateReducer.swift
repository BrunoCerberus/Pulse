import EntropyCore
import Foundation

/// Transforms domain state to view state for the Media Detail feature.
struct MediaDetailViewStateReducer: ViewStateReducing {
    func reduce(domainState: MediaDetailDomainState) -> MediaDetailViewState {
        MediaDetailViewState(
            article: domainState.article,
            isPlaying: domainState.isPlaying,
            playbackProgress: domainState.playbackProgress,
            currentTimeFormatted: formatTime(domainState.currentTime),
            durationFormatted: formatTime(domainState.duration),
            isLoading: domainState.isLoading,
            errorMessage: domainState.error,
            showShareSheet: domainState.showShareSheet,
            isBookmarked: domainState.isBookmarked
        )
    }

    /// Formats a time interval as "M:SS" or "H:MM:SS".
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
