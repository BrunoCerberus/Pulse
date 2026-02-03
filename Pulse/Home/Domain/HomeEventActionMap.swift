import EntropyCore
import Foundation

struct HomeEventActionMap: DomainEventActionMap {
    func map(event: HomeViewEvent) -> HomeDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case .onLoadMore:
            return .loadMoreHeadlines
        case let .onArticleTapped(articleId):
            return .selectArticle(articleId: articleId)
        case .onArticleNavigated:
            return .clearSelectedArticle
        case let .onBookmarkTapped(articleId):
            return .bookmarkArticle(articleId: articleId)
        case let .onShareTapped(articleId):
            return .shareArticle(articleId: articleId)
        case .onShareDismissed:
            return .clearArticleToShare
        case let .onCategorySelected(category):
            return .selectCategory(category)
        case let .onToggleTopic(topic):
            return .toggleTopic(topic)
        case .onEditTopicsTapped:
            return .setEditingTopics(true)
        case .onEditTopicsDismissed:
            return .setEditingTopics(false)
        }
    }
}
