import Foundation

enum BookmarksDomainAction: Equatable {
    case loadBookmarks
    case refresh
    case removeBookmark(articleId: String)
    case selectArticle(articleId: String)
    case clearSelectedArticle
}
