import EntropyCore
import Foundation

struct HomeEventActionMap: DomainEventActionMap {
    func map(event: HomeViewEvent) -> HomeDomainAction? {
        if let action = mapSimpleEvent(event) {
            return action
        }
        return mapPayloadEvent(event)
    }

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
