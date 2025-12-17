import Foundation
import Combine

final class CategoriesViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = CategoriesViewState
    typealias ViewEvent = CategoriesViewEvent

    @Published private(set) var viewState: CategoriesViewState = .initial
    @Published var selectedArticle: Article?

    private let interactor: CategoriesDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(interactor: CategoriesDomainInteractor = CategoriesDomainInteractor()) {
        self.interactor = interactor
        setupBindings()
    }

    func handle(event: CategoriesViewEvent) {
        switch event {
        case let .onCategorySelected(category):
            interactor.dispatch(action: .selectCategory(category))
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case .onRefresh:
            interactor.dispatch(action: .refresh)
        case let .onArticleTapped(article):
            selectedArticle = article
            interactor.dispatch(action: .selectArticle(article))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                CategoriesViewState(
                    categories: NewsCategory.allCases,
                    selectedCategory: state.selectedCategory,
                    articles: state.articles.map { ArticleViewItem(from: $0) },
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && state.articles.isEmpty && state.selectedCategory != nil
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

struct CategoriesViewState: Equatable {
    var categories: [NewsCategory]
    var selectedCategory: NewsCategory?
    var articles: [ArticleViewItem]
    var isLoading: Bool
    var isLoadingMore: Bool
    var errorMessage: String?
    var showEmptyState: Bool

    static var initial: CategoriesViewState {
        CategoriesViewState(
            categories: NewsCategory.allCases,
            selectedCategory: nil,
            articles: [],
            isLoading: false,
            isLoadingMore: false,
            errorMessage: nil,
            showEmptyState: false
        )
    }
}

enum CategoriesViewEvent: Equatable {
    case onCategorySelected(NewsCategory)
    case onLoadMore
    case onRefresh
    case onArticleTapped(Article)
}
