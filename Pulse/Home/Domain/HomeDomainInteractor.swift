import Combine
import Foundation

final class HomeDomainInteractor: CombineInteractor {
    typealias DomainState = HomeDomainState
    typealias DomainAction = HomeDomainAction

    private let newsService: NewsService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<HomeDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    var statePublisher: AnyPublisher<HomeDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: HomeDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            newsService = try serviceLocator.retrieve(NewsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve NewsService: \(error)", level: .warning)
            newsService = LiveNewsService()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: HomeDomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .loadMoreHeadlines:
            loadMoreHeadlines()
        case .refresh:
            refresh()
        case let .selectArticle(article):
            selectArticle(article)
        case .clearSelectedArticle:
            clearSelectedArticle()
        case let .bookmarkArticle(article):
            toggleBookmark(article)
        case let .shareArticle(article):
            shareArticle(article)
        case .clearArticleToShare:
            clearArticleToShare()
        }
    }

    private func loadInitialData() {
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        // NewsAPI free tier has best coverage for US
        let country = "us"

        Publishers.Zip(
            newsService.fetchBreakingNews(country: country),
            newsService.fetchTopHeadlines(country: country, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] breaking, headlines in
            self?.updateState { state in
                state.breakingNews = breaking
                state.headlines = self?.deduplicateArticles(headlines, excluding: breaking) ?? headlines
                state.isLoading = false
                state.currentPage = 1
                state.hasMorePages = headlines.count >= 20
                state.hasLoadedInitialData = true
            }
            // Update widget with latest headlines
            let allArticles = breaking + headlines
            WidgetDataManager.shared.saveArticlesForWidget(allArticles)
        }
        .store(in: &cancellables)
    }

    private func loadMoreHeadlines() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        // NewsAPI free tier has best coverage for US
        let country = "us"
        let nextPage = currentState.currentPage + 1

        newsService.fetchTopHeadlines(country: country, page: nextPage)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.updateState { state in
                        state.isLoadingMore = false
                    }
                }
            } receiveValue: { [weak self] articles in
                guard let self else { return }
                self.updateState { state in
                    let existingIDs = Set(state.headlines.map { $0.id } + state.breakingNews.map { $0.id })
                    let newArticles = articles.filter { !existingIDs.contains($0.id) }
                    state.headlines.append(contentsOf: newArticles)
                    state.isLoadingMore = false
                    state.currentPage = nextPage
                    state.hasMorePages = articles.count >= 20
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        updateState { state in
            state.isRefreshing = true
            state.breakingNews = []
            state.headlines = []
            state.error = nil
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
        }

        let country = "us"

        Publishers.Zip(
            newsService.fetchBreakingNews(country: country),
            newsService.fetchTopHeadlines(country: country, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isRefreshing = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] breaking, headlines in
            self?.updateState { state in
                state.breakingNews = breaking
                state.headlines = self?.deduplicateArticles(headlines, excluding: breaking) ?? headlines
                state.isRefreshing = false
                state.currentPage = 1
                state.hasMorePages = headlines.count >= 20
                state.hasLoadedInitialData = true
            }
            let allArticles = breaking + headlines
            WidgetDataManager.shared.saveArticlesForWidget(allArticles)
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

    private func shareArticle(_ article: Article) {
        updateState { state in
            state.articleToShare = article
        }
    }

    private func clearArticleToShare() {
        updateState { state in
            state.articleToShare = nil
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

    private func toggleBookmark(_ article: Article) {
        let task = Task { [weak self] in
            guard let self else { return }
            let isBookmarked = await storageService.isBookmarked(article.id)
            if isBookmarked {
                try? await storageService.deleteArticle(article)
            } else {
                try? await storageService.saveArticle(article)
            }
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

    private func deduplicateArticles(_ articles: [Article], excluding: [Article]) -> [Article] {
        let excludeIDs = Set(excluding.map { $0.id })
        return articles.filter { !excludeIDs.contains($0.id) }
    }

    private func updateState(_ transform: (inout HomeDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
