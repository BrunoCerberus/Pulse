import EntropyCore
import Foundation

/// Maps view events to domain actions for the Article Detail feature.
///
/// This mapper decouples the view layer from domain logic,
/// allowing independent testing of each layer.
///
/// ## Mappings
/// - `onAppear` → `onAppear` (load bookmark status, process content)
/// - `onBookmarkTapped` → `toggleBookmark`
/// - `onShareTapped` → `showShareSheet`
/// - `onSummarizeTapped` → `showSummarizationSheet` (Premium feature)
/// - `onReadFullTapped` → `openInBrowser`
struct ArticleDetailEventActionMap: DomainEventActionMap {
    /// Maps a view event to its corresponding domain action.
    /// - Parameter event: The view event from the UI layer.
    /// - Returns: The domain action to dispatch, or `nil` if no mapping exists.
    func map(event: ArticleDetailViewEvent) -> ArticleDetailDomainAction? {
        switch event {
        case .onAppear:
            return .onAppear
        case .onBookmarkTapped:
            return .toggleBookmark
        case .onShareTapped:
            return .showShareSheet
        case .onSummarizeTapped:
            return .showSummarizationSheet
        case .onReadFullTapped:
            return .openInBrowser
        case .onListenTapped:
            return .startTTS
        case .onTTSPlayPauseTapped:
            return .toggleTTSPlayback
        default:
            return mapTTSEvent(event)
        }
    }

    private func mapTTSEvent(_ event: ArticleDetailViewEvent) -> ArticleDetailDomainAction? {
        switch event {
        case .onDisappear, .onTTSStopTapped:
            return .stopTTS
        case .onShareSheetDismissed:
            return .dismissShareSheet
        case .onSummarizationSheetDismissed:
            return .dismissSummarizationSheet
        case .onTTSSpeedTapped:
            return .cycleTTSSpeed
        default:
            return nil
        }
    }
}
