import EntropyCore
import Foundation

/// Maps view events to domain actions for the Home feature.
///
/// This mapper decouples the view layer from domain logic,
/// allowing independent testing of each layer. Events are split
/// into simple (no payload) and payload events for cleaner mapping.
///
/// ## Event Categories
/// - **Simple events**: onAppear, onRefresh, onLoadMore, etc.
/// - **Payload events**: onArticleTapped, onCategorySelected, etc.
struct HomeEventActionMap: DomainEventActionMap {
    /// Maps a view event to its corresponding domain action.
    /// - Parameter event: The view event from the UI layer.
    /// - Returns: The domain action to dispatch, or `nil` if no mapping exists.
    func map(event: HomeViewEvent) -> HomeDomainAction? {
        if let action = mapSimpleEvent(event) {
            return action
        }
        return mapPayloadEvent(event)
    }

    /// Maps simple events that don't carry payload data.
    /// - Parameter event: The view event to map.
    /// - Returns: The corresponding domain action, or `nil` for payload events.
    private func mapSimpleEvent(_ event: HomeViewEvent) -> HomeDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case .onLoadMore:
            return .loadMoreHeadlines
        case .onArticleNavigated:
            return .clearSelectedArticle
        case .onShareDismissed:
            return .clearArticleToShare
        case .onEditTopicsTapped:
            return .setEditingTopics(true)
        case .onEditTopicsDismissed:
            return .setEditingTopics(false)
        default:
            return nil
        }
    }

    /// Maps events that carry payload data (article IDs, categories, etc.).
    /// - Parameter event: The view event to map.
    /// - Returns: The corresponding domain action with payload, or `nil` for simple events.
    private func mapPayloadEvent(_ event: HomeViewEvent) -> HomeDomainAction? {
        switch event {
        case let .onArticleTapped(articleId):
            return .selectArticle(articleId: articleId)
        case let .onBookmarkTapped(articleId):
            return .bookmarkArticle(articleId: articleId)
        case let .onShareTapped(articleId):
            return .shareArticle(articleId: articleId)
        case let .onCategorySelected(category):
            return .selectCategory(category)
        case let .onToggleTopic(topic):
            return .toggleTopic(topic)
        default:
            return nil
        }
    }
}
