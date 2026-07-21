import Combine
import EntropyCore
import Foundation

/// ViewModel for the Search screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Provides debounced search (300ms) to reduce API calls during typing.
///
/// ## Features
/// - Full-text search with pagination
/// - Autocomplete suggestions
/// - Sort options (relevance, date, popularity)
/// - 300ms debounce on query changes
@MainActor
final class SearchViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SearchViewState
    typealias ViewEvent = SearchViewEvent

    @Published private(set) var viewState: SearchViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: SearchDomainInteractor
    private var cancellables = Set<AnyCancellable>()
    private let searchQuerySubject = PassthroughSubject<String, Never>()
    /// Query for which `.search` was last dispatched, used to collapse the multiple search
    /// trigger paths (debounce, submit, suggestion tap) into a single search per user intent.
    private var lastSearchedQuery: String?

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = SearchDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
        setupDebouncedSearch()
    }

    // swiftlint:disable:next cyclomatic_complexity
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
            // Use the interactor's query (updated synchronously by `.updateQuery`)
            // rather than `viewState.query`, which lags behind the async state
            // binding — a submit immediately after a keystroke would otherwise
            // read the stale (empty) query and skip the search.
            dispatchSearch(for: interactor.currentState.query)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case .onClear:
            lastSearchedQuery = nil
            interactor.dispatch(action: .clearResults)
        case let .onSortChanged(option):
            interactor.dispatch(action: .setSortOption(option))
        case let .onArticleTapped(articleId):
            interactor.dispatch(action: .selectArticle(articleId: articleId))
        case .onArticleNavigated:
            interactor.dispatch(action: .clearSelectedArticle)
        case let .onSuggestionTapped(suggestion):
            interactor.dispatch(action: .updateQuery(suggestion))
            dispatchSearch(for: suggestion)
        case let .onBookmarkTapped(articleId):
            interactor.dispatch(action: .bookmarkArticle(articleId: articleId))
        case let .onShareTapped(articleId):
            interactor.dispatch(action: .shareArticle(articleId: articleId))
        case .onShareDismissed:
            interactor.dispatch(action: .clearArticleToShare)
        }
    }

    private func setupDebouncedSearch() {
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.dispatchSearch(for: query)
            }
            .store(in: &cancellables)
    }

    /// Single entry point for triggering a search. Collapses the debounce, submit, and
    /// suggestion-tap paths into one search per distinct query so a typed query immediately
    /// followed by submit (or a suggestion tap matching the pending debounce) doesn't fire a
    /// duplicate network round-trip and duplicate `searchPerformed` analytics event.
    private func dispatchSearch(for query: String) {
        guard !query.isEmpty, query != lastSearchedQuery else { return }
        lastSearchedQuery = query
        interactor.dispatch(action: .search)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                SearchViewState(
                    query: state.query,
                    results: state.results.enumerated().map { index, article in
                        ArticleViewItem(from: article, index: index, isRead: state.readArticleIDs.contains(article.id))
                    },
                    suggestions: state.suggestions,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isSorting: state.isSorting,
                    errorMessage: state.error,
                    showNoResults: state.hasSearched && !state.isLoading && !state.isSorting && state.results.isEmpty,
                    hasSearched: state.hasSearched,
                    sortOption: state.sortBy,
                    selectedArticle: state.selectedArticle,
                    isOfflineError: state.isOfflineError,
                    articleToShare: state.articleToShare,
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
