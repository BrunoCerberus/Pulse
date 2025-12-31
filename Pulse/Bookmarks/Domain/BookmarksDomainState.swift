import Foundation

struct BookmarksDomainState: Equatable {
    var bookmarks: [Article]
    var isLoading: Bool
    var isRefreshing: Bool
    var error: String?
    var selectedArticle: Article?

    static var initial: BookmarksDomainState {
        BookmarksDomainState(
            bookmarks: [],
            isLoading: false,
            isRefreshing: false,
            error: nil,
            selectedArticle: nil
        )
    }
}
