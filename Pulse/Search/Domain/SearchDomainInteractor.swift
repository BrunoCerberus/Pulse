import Combine
import EntropyCore
import Foundation

final class SearchDomainInteractor: CombineInteractor {
    typealias DomainState = SearchDomainState
    typealias DomainAction = SearchDomainAction

    private let searchService: SearchService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<SearchDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<SearchDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: SearchDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            searchService = try serviceLocator.retrieve(SearchService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SearchService: \(error)", level: .warning)
            searchService = LiveSearchService()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: SearchDomainAction) {
        switch action {
        case let .updateQuery(query):
            updateQuery(query)
        case .search:
            performSearch()
        case .loadMore:
            loadMore()
        case .clearResults:
            clearResults()
        case let .setSortOption(option):
            setSortOption(option)
        case let .selectArticle(articleId):
            if let article = findArticle(by: articleId) {
                selectArticle(article)
            }
        case .clearSelectedArticle:
            clearSelectedArticle()
        }
    }

    private func findArticle(by id: String) -> Article? {
        currentState.results.first { $0.id == id }
    }

    private func updateQuery(_ query: String) {
        updateState { state in
            state.query = query
        }

        searchCancellable?.cancel()

        guard !query.isEmpty else {
            updateState { state in
                state.suggestions = []
            }
            return
        }

        searchService.getSuggestions(for: query)
            .sink { [weak self] suggestions in
                self?.updateState { state in
                    state.suggestions = suggestions
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch() {
        let query = currentState.query
        guard !query.isEmpty else { return }

        searchCancellable?.cancel()

        updateState { state in
            state.isLoading = true
            state.error = nil
            state.currentPage = 1
            state.results = []
            state.hasSearched = true
        }

        searchCancellable = searchService.search(
            query: query,
            page: 1,
            sortBy: currentState.sortBy.rawValue
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] articles in
            self?.updateState { state in
                state.results = articles
                state.isLoading = false
                state.hasMorePages = articles.count >= 20
            }
        }
    }

    private func loadMore() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        let nextPage = currentState.currentPage + 1

        searchService.search(
            query: currentState.query,
            page: nextPage,
            sortBy: currentState.sortBy.rawValue
        )
        .sink { [weak self] completion in
            if case .failure = completion {
                self?.updateState { state in
                    state.isLoadingMore = false
                }
            }
        } receiveValue: { [weak self] articles in
            self?.updateState { state in
                let existingIDs = Set(state.results.map { $0.id })
                let newArticles = articles.filter { !existingIDs.contains($0.id) }
                state.results.append(contentsOf: newArticles)
                state.isLoadingMore = false
                state.currentPage = nextPage
                state.hasMorePages = articles.count >= 20
            }
        }
        .store(in: &cancellables)
    }

    private func clearResults() {
        updateState { state in
            state.query = ""
            state.results = []
            state.suggestions = []
            state.error = nil
            state.hasSearched = false
        }
    }

    private func setSortOption(_ option: SearchSortOption) {
        updateState { state in
            state.sortBy = option
        }

        if !currentState.query.isEmpty, currentState.hasSearched {
            performSortedSearch()
        }
    }

    private func performSortedSearch() {
        let query = currentState.query

        searchCancellable?.cancel()

        updateState { state in
            state.isSorting = true
            state.error = nil
            state.currentPage = 1
        }

        searchCancellable = searchService.search(
            query: query,
            page: 1,
            sortBy: currentState.sortBy.rawValue
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isSorting = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] articles in
            self?.updateState { state in
                state.results = articles
                state.isSorting = false
                state.hasMorePages = articles.count >= 20
            }
        }
    }

    private func selectArticle(_ article: Article) {
        updateState { state in
            state.selectedArticle = article
        }
        let task = Task { [weak self] in
            guard let self else { return }
            try? await storageService.saveReadingHistory(article)
        }
        backgroundTasks.insert(task)
        Task { [weak self] in
            guard let self else { return }
            await task.value
            backgroundTasks.remove(task)
        }
    }

    deinit {
        backgroundTasks.forEach { $0.cancel() }
    }

    private func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    private func updateState(_ transform: (inout SearchDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
