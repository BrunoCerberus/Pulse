import Foundation

enum FeedViewEvent: Equatable {
    case onAppear
    case onGenerateDigestTapped
    case onArticleTapped(Article)
    case onArticleNavigated
    case onRetryTapped
    case onDismissError
}
