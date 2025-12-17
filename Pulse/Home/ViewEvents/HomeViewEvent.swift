import Foundation

enum HomeViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case onArticleTapped(Article)
    case onBookmarkTapped(Article)
    case onShareTapped(Article)
}
