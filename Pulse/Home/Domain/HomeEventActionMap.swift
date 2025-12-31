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
        case let .onArticleTapped(article):
            return .selectArticle(article)
        case .onArticleNavigated:
            return .clearSelectedArticle
        case let .onBookmarkTapped(article):
            return .bookmarkArticle(article)
        case let .onShareTapped(article):
            return .shareArticle(article)
        case .onShareDismissed:
            return .clearArticleToShare
        }
    }
}
