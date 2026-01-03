import Combine
import Foundation

final class CategoriesDomainInteractor: CombineInteractor {
    typealias DomainState = CategoriesDomainState
    typealias DomainAction = CategoriesDomainAction

    private let categoriesService: CategoriesService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<CategoriesDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<CategoriesDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: CategoriesDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            categoriesService = try serviceLocator.retrieve(CategoriesService.self)
        } catch {
            Logger.shared.service("Failed to retrieve CategoriesService: \(error)", level: .warning)
            categoriesService = LiveCategoriesService()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: CategoriesDomainAction) {
        switch action {
        case let .selectCategory(category):
            selectCategory(category)
        case .loadMore:
            loadMore()
        case .refresh:
            refresh()
        case let .selectArticle(article):
            selectArticle(article)
        case .clearSelectedArticle:
            clearSelectedArticle()
        }
    }

    private func selectCategory(_ category: NewsCategory) {
        // Skip if same category is already loaded
        if currentState.selectedCategory == category, currentState.hasLoadedInitialData {
            return
        }

        updateState { state in
            state.selectedCategory = category
            state.isLoading = true
            state.error = nil
            state.currentPage = 1
            state.articles = []
            state.hasLoadedInitialData = false
        }

        categoriesService.fetchArticles(for: category, page: 1)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.updateState { state in
                    state.articles = articles
                    state.isLoading = false
                    state.hasMorePages = articles.count >= 20
                    state.hasLoadedInitialData = true
                }
            }
            .store(in: &cancellables)
    }

    private func loadMore() {
        guard let category = currentState.selectedCategory,
              !currentState.isLoadingMore,
              currentState.hasMorePages
        else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        let nextPage = currentState.currentPage + 1

        categoriesService.fetchArticles(for: category, page: nextPage)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.updateState { state in
                        state.isLoadingMore = false
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.updateState { state in
                    let existingIDs = Set(state.articles.map { $0.id })
                    let newArticles = articles.filter { !existingIDs.contains($0.id) }
                    state.articles.append(contentsOf: newArticles)
                    state.isLoadingMore = false
                    state.currentPage = nextPage
                    state.hasMorePages = articles.count >= 20
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        guard let category = currentState.selectedCategory else { return }

        updateState { state in
            state.isRefreshing = true
            state.articles = []
            state.error = nil
            state.currentPage = 1
            state.hasLoadedInitialData = false
        }

        categoriesService.fetchArticles(for: category, page: 1)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isRefreshing = false
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.updateState { state in
                    state.articles = articles
                    state.isRefreshing = false
                    state.hasMorePages = articles.count >= 20
                    state.hasLoadedInitialData = true
                }
            }
            .store(in: &cancellables)
    }

    private func selectArticle(_ article: Article) {
        updateState { state in
            state.selectedArticle = article
        }
        saveToReadingHistory(article)
    }

    private func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    private func saveToReadingHistory(_ article: Article) {
        let task = Task { [weak self] in
            guard let self else { return }
            try? await storageService.saveReadingHistory(article)
        }
        backgroundTasks.insert(task)
        Task {
            await task.value
            backgroundTasks.remove(task)
        }
    }

    deinit {
        backgroundTasks.forEach { $0.cancel() }
    }

    private func updateState(_ transform: (inout CategoriesDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

enum CategoriesDomainAction: Equatable {
    case selectCategory(NewsCategory)
    case loadMore
    case refresh
    case selectArticle(Article)
    case clearSelectedArticle
}
