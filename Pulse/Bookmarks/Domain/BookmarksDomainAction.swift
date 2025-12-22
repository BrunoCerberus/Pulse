import Foundation

enum BookmarksDomainAction: Equatable {
    case loadBookmarks
    case refresh
    case removeBookmark(Article)
    case selectArticle(Article)
}
