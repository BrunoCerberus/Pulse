import Foundation

enum HomeViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case onArticleTapped(Article)
    case onArticleNavigated
    case onBookmarkTapped(Article)
    case onShareTapped(Article)
    case onShareDismissed
}
