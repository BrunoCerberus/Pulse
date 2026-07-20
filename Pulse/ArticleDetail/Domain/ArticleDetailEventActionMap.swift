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
            .onAppear
        case .onBookmarkTapped:
            .toggleBookmark
        case .onShareTapped:
            .showShareSheet
        case .onSummarizeTapped:
            .showSummarizationSheet
        case .onReadFullTapped:
            .openInBrowser
        case .onListenTapped:
            .listen
        case .onShareSheetDismissed:
            .dismissShareSheet
        case .onSummarizationSheetDismissed:
            .dismissSummarizationSheet
        case .onDisappear:
            // Deliberately unmapped: playback lives in the global queue and
            // must survive navigating away from the article.
            nil
        }
    }
}
