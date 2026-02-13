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
/// - `onRetryTapped` → `generateDigest` (retry after error)
/// - `onDismissError` → `clearError`
struct FeedEventActionMap: DomainEventActionMap {
    /// Maps a view event to its corresponding domain action.
    /// - Parameter event: The view event from the UI layer.
    /// - Returns: The domain action to dispatch, or `nil` if no mapping exists.
    func map(event: FeedViewEvent) -> FeedDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onGenerateDigestTapped:
            return .generateDigest
        case let .onArticleTapped(article):
            return .selectArticle(article)
        case .onArticleNavigated:
            return .clearSelectedArticle
        case .onRetryTapped:
            return .generateDigest
        case .onDismissError:
            return .clearError
        }
    }
}
