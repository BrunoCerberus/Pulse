import EntropyCore
import Foundation

struct FeedEventActionMap: DomainEventActionMap {
    func map(event: FeedViewEvent) -> FeedDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case .onGenerateDigestTapped:
            return .generateDigest
        case let .onArticleTapped(article):
            return .selectArticle(article)
        case .onArticleNavigated:
            return .clearSelectedArticle
        case .onRetryTapped:
            return .refresh
        case .onDismissError:
            return .clearError
        }
    }
}
