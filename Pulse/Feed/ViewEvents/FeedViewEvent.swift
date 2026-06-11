import Foundation

enum FeedViewEvent: Equatable {
    case onAppear
    case onGenerateDigestTapped
    case onListenBriefingTapped
    case onArticleTapped(Article)
    case onArticleNavigated
    case onRetryTapped
    case onDismissError
}
