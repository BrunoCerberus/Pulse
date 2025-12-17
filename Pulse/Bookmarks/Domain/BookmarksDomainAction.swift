import Foundation

enum BookmarksDomainAction: Equatable {
    case loadBookmarks
    case removeBookmark(Article)
    case selectArticle(Article)
}
