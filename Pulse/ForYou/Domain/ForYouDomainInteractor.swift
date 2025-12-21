import Combine
import Foundation

final class ForYouDomainInteractor: CombineInteractor {
    typealias DomainState = ForYouDomainState
    typealias DomainAction = ForYouDomainAction

    private let forYouService: ForYouService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<ForYouDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    /// Time when data finished loading - pagination is disabled for a brief period after each load
    private var lastLoadCompletedAt: Date?
    private let paginationCooldown: TimeInterval = 1.0

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
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
            state.currentPage = 1
        }

        Task {
            let preferences = try? await storageService.fetchUserPreferences() ?? .default
            await MainActor.run {
                updateState { state in
                    state.preferences = preferences ?? .default
                }
            }

            forYouService.fetchPersonalizedFeed(preferences: preferences ?? .default, page: 1)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                    }
                } receiveValue: { [weak self] articles in
                    self?.lastLoadCompletedAt = Date()
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
        // Wait for previous load to complete and cooldown to pass before allowing pagination
        guard let loadTime = lastLoadCompletedAt,
              Date().timeIntervalSince(loadTime) >= paginationCooldown,
              !currentState.isLoadingMore,
              currentState.hasMorePages
        else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        let nextPage = currentState.currentPage + 1

        forYouService.fetchPersonalizedFeed(preferences: currentState.preferences, page: nextPage)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.lastLoadCompletedAt = Date()
                    self?.updateState { state in
                        state.isLoadingMore = false
                    }
                }
            } receiveValue: { [weak self] articles in
                self?.lastLoadCompletedAt = Date()
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
        lastLoadCompletedAt = nil
        updateState { state in
            state.hasLoadedInitialData = false
        }
        loadFeed()
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
