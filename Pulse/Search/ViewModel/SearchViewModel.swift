import Combine
import Foundation

final class SearchViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SearchViewState
    typealias ViewEvent = SearchViewEvent

    @Published private(set) var viewState: SearchViewState = .initial
    @Published var selectedArticle: Article?

    private let serviceLocator: ServiceLocator
    private let interactor: SearchDomainInteractor
    private var cancellables = Set<AnyCancellable>()
    private var searchWorkItem: DispatchWorkItem?

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = SearchDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: SearchViewEvent) {
        switch event {
        case let .onQueryChanged(query):
            interactor.dispatch(action: .updateQuery(query))
            debounceSearch(query: query)
        case .onSearch:
            searchWorkItem?.cancel()
            interactor.dispatch(action: .search)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case .onClear:
            searchWorkItem?.cancel()
            interactor.dispatch(action: .clearResults)
        case let .onSortChanged(option):
            interactor.dispatch(action: .setSortOption(option))
        case let .onArticleTapped(article):
            selectedArticle = article
            interactor.dispatch(action: .selectArticle(article))
        case let .onSuggestionTapped(suggestion):
            searchWorkItem?.cancel()
            interactor.dispatch(action: .updateQuery(suggestion))
            interactor.dispatch(action: .search)
        }
    }

    private func debounceSearch(query: String) {
        searchWorkItem?.cancel()

        guard !query.isEmpty else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.interactor.dispatch(action: .search)
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                SearchViewState(
                    query: state.query,
                    results: state.results.map { ArticleViewItem(from: $0) },
                    suggestions: state.suggestions,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isSorting: state.isSorting,
                    errorMessage: state.error,
                    showNoResults: state.hasSearched && !state.isLoading && !state.isSorting && state.results.isEmpty,
                    hasSearched: state.hasSearched,
                    sortOption: state.sortBy
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
