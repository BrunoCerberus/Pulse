import Foundation

enum HomeViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case onArticleTapped(articleId: String)
    case onArticleNavigated
    case onBookmarkTapped(articleId: String)
    case onShareTapped(articleId: String)
    case onShareDismissed
    case onCategorySelected(NewsCategory?)
    case onToggleTopic(NewsCategory)
    case onEditTopicsTapped
    case onEditTopicsDismissed
}
