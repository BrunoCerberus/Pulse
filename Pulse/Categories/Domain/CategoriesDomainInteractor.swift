import Foundation
import Combine

final class CategoriesDomainInteractor: CombineInteractor {
    typealias DomainState = CategoriesDomainState
    typealias DomainAction = CategoriesDomainAction

    private let categoriesService: CategoriesService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<CategoriesDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<CategoriesDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: CategoriesDomainState {
        stateSubject.value
    }

    init(
        categoriesService: CategoriesService = ServiceLocator.shared.resolve(CategoriesService.self),
        storageService: StorageService = ServiceLocator.shared.resolve(StorageService.self)
    ) {
        self.categoriesService = categoriesService
        self.storageService = storageService
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
            saveToReadingHistory(article)
        }
    }

    private func selectCategory(_ category: NewsCategory) {
        updateState { state in
            state.selectedCategory = category
            state.isLoading = true
            state.error = nil
            state.currentPage = 1
            state.articles = []
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
                }
            }
            .store(in: &cancellables)
    }

    private func loadMore() {
        guard let category = currentState.selectedCategory,
              !currentState.isLoadingMore,
              currentState.hasMorePages else { return }

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
        selectCategory(category)
    }

    private func saveToReadingHistory(_ article: Article) {
        Task {
            try? await storageService.saveReadingHistory(article)
        }
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
}
