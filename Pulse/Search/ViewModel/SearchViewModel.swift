import Foundation
import Combine

final class SearchViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SearchViewState
    typealias ViewEvent = SearchViewEvent

    @Published private(set) var viewState: SearchViewState = .initial
    @Published var selectedArticle: Article?

    private let interactor: SearchDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(interactor: SearchDomainInteractor = SearchDomainInteractor()) {
        self.interactor = interactor
        setupBindings()
    }

    func handle(event: SearchViewEvent) {
        switch event {
        case let .onQueryChanged(query):
            interactor.dispatch(action: .updateQuery(query))
        case .onSearch:
            interactor.dispatch(action: .search)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case .onClear:
            interactor.dispatch(action: .clearResults)
        case let .onSortChanged(option):
            interactor.dispatch(action: .setSortOption(option))
        case let .onArticleTapped(article):
            selectedArticle = article
            interactor.dispatch(action: .selectArticle(article))
        case let .onSuggestionTapped(suggestion):
            interactor.dispatch(action: .updateQuery(suggestion))
            interactor.dispatch(action: .search)
        }
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
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && state.results.isEmpty && !state.query.isEmpty,
                    sortOption: state.sortBy
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
