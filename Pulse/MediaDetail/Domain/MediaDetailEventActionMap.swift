import EntropyCore
import Foundation

/// Maps view events to domain actions for the Media Detail feature.
struct MediaDetailEventActionMap: DomainEventActionMap {
    func map(event: MediaDetailViewEvent) -> MediaDetailDomainAction? {
        if let action = mapSimple(event: event) {
            return action
        }

        switch event {
        case .onPlayPauseTapped:
            return nil // Handled by ViewModel based on current state

        case let .onSeek(progress):
            return .seek(progress: progress)

        case let .onProgressUpdate(progress, currentTime):
            return .playbackProgressUpdated(progress: progress, currentTime: currentTime)

        case let .onDurationLoaded(duration):
            return .durationLoaded(duration)

        case let .onError(message):
            return .playbackError(message)

        default:
            return nil
        }
    }

    private func mapSimple(event: MediaDetailViewEvent) -> MediaDetailDomainAction? {
        switch event {
        case .onAppear:
            .onAppear
        case .onSkipBackwardTapped:
            .skipBackward(seconds: 15)
        case .onSkipForwardTapped:
            .skipForward(seconds: 30)
        case .onPlayerLoading:
            .playerLoading
        case .onPlayerReady:
            .playerReady
        case .onShareTapped:
            .showShareSheet
        case .onShareDismissed:
            .dismissShareSheet
        case .onBookmarkTapped:
            .toggleBookmark
        case .onOpenInBrowserTapped:
            .openInBrowser
        default:
            nil
        }
    }
}
