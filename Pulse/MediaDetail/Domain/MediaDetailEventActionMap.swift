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
            return .onAppear
        case .onSkipBackwardTapped:
            return .skipBackward(seconds: 15)
        case .onSkipForwardTapped:
            return .skipForward(seconds: 30)
        case .onPlayerLoading:
            return .playerLoading
        case .onPlayerReady:
            return .playerReady
        case .onShareTapped:
            return .showShareSheet
        case .onShareDismissed:
            return .dismissShareSheet
        case .onBookmarkTapped:
            return .toggleBookmark
        case .onOpenInBrowserTapped:
            return .openInBrowser
        default:
            return nil
        }
    }
}
