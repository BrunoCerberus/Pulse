import Foundation

struct HomeViewState: Equatable {
    var breakingNews: [ArticleViewItem]
    var headlines: [ArticleViewItem]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool

    static var initial: HomeViewState {
        HomeViewState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false
        )
    }
}

struct ArticleViewItem: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let sourceName: String
    let imageURL: URL?
    let formattedDate: String
    let category: NewsCategory?
    let article: Article

    init(from article: Article) {
        id = article.id
        title = article.title
        description = article.description
        sourceName = article.source.name
        imageURL = article.imageURL.flatMap { URL(string: $0) }
        formattedDate = article.formattedDate
        category = article.category
        self.article = article
    }
}
