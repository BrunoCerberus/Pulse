import Foundation

enum FeedViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onGenerateDigestTapped
    case onArticleTapped(Article)
    case onArticleNavigated
    case onRetryTapped
    case onDismissError
}
