import EntropyCore
import Foundation

/// Maps view events to domain actions for the Media Detail feature.
struct MediaDetailEventActionMap: DomainEventActionMap {
    func map(event: MediaDetailViewEvent) -> MediaDetailDomainAction? {
        switch event {
        // Lifecycle
        case .onAppear:
            return .onAppear
        // Playback control
        case .onPlayPauseTapped:
            return nil // Handled by ViewModel based on current state
        case let .onSeek(progress):
            return .seek(to: progress)
        case .onSkipBackwardTapped:
            return .skipBackward(seconds: 15)
        case .onSkipForwardTapped:
            return .skipForward(seconds: 30)
        // Playback events from player
        case let .onProgressUpdate(progress, currentTime):
            return .playbackProgressUpdated(progress: progress, currentTime: currentTime)
        case let .onDurationLoaded(duration):
            return .durationLoaded(duration)
        case .onPlayerLoading:
            return .playerLoading
        case .onPlayerReady:
            return .playerReady
        case let .onError(message):
            return .playbackError(message)
        // Actions
        case .onShareTapped:
            return .showShareSheet
        case .onShareDismissed:
            return .dismissShareSheet
        case .onBookmarkTapped:
            return .toggleBookmark
        case .onOpenInBrowserTapped:
            return .openInBrowser
        }
    }
}
