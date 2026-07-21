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
            .loadInitialData
        case .onRefresh:
            .refresh
        case .onLoadMore:
            .loadMoreHeadlines
        case .onArticleNavigated:
            .clearSelectedArticle
        case .onShareDismissed:
            .clearArticleToShare
        case .onEditTopicsTapped:
            .setEditingTopics(true)
        case .onEditTopicsDismissed:
            .setEditingTopics(false)
        default:
            nil
        }
    }

    /// Maps events that carry payload data (article IDs, categories, etc.).
    /// - Parameter event: The view event to map.
    /// - Returns: The corresponding domain action with payload, or `nil` for simple events.
    private func mapPayloadEvent(_ event: HomeViewEvent) -> HomeDomainAction? {
        switch event {
        case let .onArticleTapped(articleId):
            .selectArticle(articleId: articleId)
        case let .onBookmarkTapped(articleId):
            .bookmarkArticle(articleId: articleId)
        case let .onShareTapped(articleId):
            .shareArticle(articleId: articleId)
        case let .onCategorySelected(category):
            .selectCategory(category)
        case let .onToggleTopic(topic):
            .toggleTopic(topic)
        case let .onRecentlyReadTapped(articleId):
            .selectRecentlyRead(articleId: articleId)
        default:
            nil
        }
    }
}
