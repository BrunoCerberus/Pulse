import EntropyCore
import Foundation

/// Maps view events to domain actions for the Feed feature.
///
/// This mapper decouples the view layer from domain logic,
/// allowing independent testing of each layer.
///
/// ## Mappings
/// - `onAppear` → `loadInitialData`
/// - `onGenerateDigestTapped` → `generateDigest`
/// - `onArticleTapped` → `selectArticle`
/// - `onRetryTapped` → `retryAfterError` (retry after error)
/// - `onDismissError` → `clearError`
struct FeedEventActionMap: DomainEventActionMap {
    /// Maps a view event to its corresponding domain action.
    /// - Parameter event: The view event from the UI layer.
    /// - Returns: The domain action to dispatch, or `nil` if no mapping exists.
    func map(event: FeedViewEvent) -> FeedDomainAction? {
        switch event {
        case .onAppear:
            .loadInitialData
        case .onGenerateDigestTapped:
            .generateDigest
        case .onListenBriefingTapped:
            .startAudioBriefing
        case .onMorningBriefingTapped:
            .startMorningBriefing
        case let .onArticleTapped(article):
            .selectArticle(article)
        case .onArticleNavigated:
            .clearSelectedArticle
        case .onRetryTapped:
            .retryAfterError
        case .onDismissError:
            .clearError
        }
    }
}
