import Combine
import Foundation

final class CategoriesViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = CategoriesViewState
    typealias ViewEvent = CategoriesViewEvent

    @Published private(set) var viewState: CategoriesViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: CategoriesDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = CategoriesDomainInteractor(serviceLocator: serviceLocator)
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
            interactor.dispatch(action: .selectArticle(article))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
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
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing
                        && state.articles.isEmpty && state.selectedCategory != nil,
                    selectedArticle: state.selectedArticle
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
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var selectedArticle: Article?

    static var initial: CategoriesViewState {
        CategoriesViewState(
            categories: NewsCategory.allCases,
            selectedCategory: nil,
            articles: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selectedArticle: nil
        )
    }
}

enum CategoriesViewEvent: Equatable {
    case onCategorySelected(NewsCategory)
    case onLoadMore
    case onRefresh
    case onArticleTapped(Article)
    case onArticleNavigated
}
