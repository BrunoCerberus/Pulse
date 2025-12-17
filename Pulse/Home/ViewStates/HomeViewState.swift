import Foundation

struct HomeViewState: Equatable {
    var breakingNews: [ArticleViewItem]
    var headlines: [ArticleViewItem]
    var isLoading: Bool
    var isLoadingMore: Bool
    var errorMessage: String?
    var showEmptyState: Bool

    static var initial: HomeViewState {
        HomeViewState(
            breakingNews: [],
            headlines: [],
            isLoading: false,
            isLoadingMore: false,
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
        self.id = article.id
        self.title = article.title
        self.description = article.description
        self.sourceName = article.source.name
        self.imageURL = article.imageURL.flatMap { URL(string: $0) }
        self.formattedDate = article.formattedDate
        self.category = article.category
        self.article = article
    }
}
