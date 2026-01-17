import Combine
import EntropyCore
import Foundation

@MainActor
final class SearchViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SearchViewState
    typealias ViewEvent = SearchViewEvent

    @Published private(set) var viewState: SearchViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: SearchDomainInteractor
    private var cancellables = Set<AnyCancellable>()
    private let searchQuerySubject = PassthroughSubject<String, Never>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = SearchDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
        setupDebouncedSearch()
    }

    func handle(event: SearchViewEvent) {
        switch event {
        case let .onQueryChanged(query):
            let currentQuery = viewState.query
            interactor.dispatch(action: .updateQuery(query))
            // Only trigger debounced search if query actually changed
            if query != currentQuery {
                searchQuerySubject.send(query)
            }
        case .onSearch:
            interactor.dispatch(action: .search)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case .onClear:
            interactor.dispatch(action: .clearResults)
        case let .onSortChanged(option):
            interactor.dispatch(action: .setSortOption(option))
        case let .onArticleTapped(articleId):
            interactor.dispatch(action: .selectArticle(articleId: articleId))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
        case let .onSuggestionTapped(suggestion):
            interactor.dispatch(action: .updateQuery(suggestion))
            interactor.dispatch(action: .search)
        }
    }

    private func setupDebouncedSearch() {
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] _ in
                self?.interactor.dispatch(action: .search)
            }
            .store(in: &cancellables)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                SearchViewState(
                    query: state.query,
                    results: state.results.enumerated().map { index, article in
                        ArticleViewItem(from: article, index: index)
                    },
                    suggestions: state.suggestions,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isSorting: state.isSorting,
                    errorMessage: state.error,
                    showNoResults: state.hasSearched && !state.isLoading && !state.isSorting && state.results.isEmpty,
                    hasSearched: state.hasSearched,
                    sortOption: state.sortBy,
                    selectedArticle: state.selectedArticle
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
