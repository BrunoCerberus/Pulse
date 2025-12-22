import Combine
import Foundation

final class ForYouDomainInteractor: CombineInteractor {
    typealias DomainState = ForYouDomainState
    typealias DomainAction = ForYouDomainAction

    private let forYouService: ForYouService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<ForYouDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<ForYouDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: ForYouDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            forYouService = try serviceLocator.retrieve(ForYouService.self)
        } catch {
            Logger.shared.service("Failed to retrieve ForYouService: \(error)", level: .warning)
            forYouService = LiveForYouService(storageService: LiveStorageService())
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: ForYouDomainAction) {
        switch action {
        case .loadFeed:
            loadFeed()
        case .loadMore:
            loadMore()
        case .refresh:
            refresh()
        case let .selectArticle(article):
            saveToReadingHistory(article)
        }
    }

    private func loadFeed() {
        guard !currentState.isLoading else { return }

        Task {
            let preferences = try? await storageService.fetchUserPreferences() ?? .default
            let currentPreferences = preferences ?? .default
            let previousPreferences = currentState.preferences

            // Skip if already loaded and preferences haven't changed
            let preferencesChanged = currentPreferences != previousPreferences
            if currentState.hasLoadedInitialData, !preferencesChanged {
                return
            }

            await MainActor.run {
                updateState { state in
                    state.isLoading = true
                    state.error = nil
                    state.currentPage = 1
                    state.preferences = currentPreferences
                    // Clear articles when preferences change
                    if preferencesChanged {
                        state.articles = []
                    }
                }
            }

            forYouService.fetchPersonalizedFeed(preferences: currentPreferences, page: 1)
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
    }

    private func loadMore() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        let nextPage = currentState.currentPage + 1

        forYouService.fetchPersonalizedFeed(preferences: currentState.preferences, page: nextPage)
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
        Task {
            let preferences = try? await storageService.fetchUserPreferences() ?? .default
            let currentPreferences = preferences ?? .default

            await MainActor.run {
                updateState { state in
                    state.isRefreshing = true
                    state.articles = []
                    state.error = nil
                    state.currentPage = 1
                    state.hasLoadedInitialData = false
                    state.preferences = currentPreferences
                }
            }

            forYouService.fetchPersonalizedFeed(preferences: currentPreferences, page: 1)
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
    }

    private func saveToReadingHistory(_ article: Article) {
        Task {
            try? await storageService.saveReadingHistory(article)
        }
    }

    private func updateState(_ transform: (inout ForYouDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}

enum ForYouDomainAction: Equatable {
    case loadFeed
    case loadMore
    case refresh
    case selectArticle(Article)
}
