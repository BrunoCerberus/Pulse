import Combine
import EntropyCore
import Foundation

/// Domain interactor for the Home feature.
///
/// Manages business logic and state for the main news feed, including:
/// - Loading breaking news carousel and headline articles
/// - Infinite scroll pagination with deduplication
/// - Pull-to-refresh with cache invalidation
/// - Article selection, bookmarking, and sharing
///
/// ## Data Flow
/// 1. Views dispatch `HomeDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `HomeDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `NewsService`: Fetches articles from Supabase/Guardian API
/// - `StorageService`: Persists reading history and bookmarks
@MainActor
// swiftlint:disable:next type_body_length
final class HomeDomainInteractor: CombineInteractor {
    typealias DomainState = HomeDomainState
    typealias DomainAction = HomeDomainAction

    private let newsService: NewsService
    private let storageService: StorageService
    private let settingsService: SettingsService
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

        do {
            settingsService = try serviceLocator.retrieve(SettingsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SettingsService: \(error)", level: .warning)
            settingsService = LiveSettingsService(storageService: storageService)
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
        case let .selectArticle(articleId):
            findArticle(by: articleId).map { selectArticle($0) }
        case .clearSelectedArticle:
            clearSelectedArticle()
        case let .bookmarkArticle(articleId):
            findArticle(by: articleId).map { toggleBookmark($0) }
        case let .shareArticle(articleId):
            findArticle(by: articleId).map { shareArticle($0) }
        case .clearArticleToShare:
            clearArticleToShare()
        case let .selectCategory(category):
            handleSelectCategory(category)
        }
    }

    private func findArticle(by id: String) -> Article? {
        currentState.breakingNews.first { $0.id == id }
            ?? currentState.headlines.first { $0.id == id }
    }

    private func loadInitialData() {
        // Always reload followed topics from preferences (even if data is already loaded)
        // This ensures topics are refreshed when returning from Settings
        loadFollowedTopics()

        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        // NewsAPI free tier has best coverage for US
        let country = "us"
        let selectedCategory = currentState.selectedCategory

        // When a category is selected, only fetch headlines for that category (no breaking news)
        if let category = selectedCategory {
            newsService.fetchTopHeadlines(category: category, country: country, page: 1)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                    }
                } receiveValue: { [weak self] headlines in
                    self?.updateState { state in
                        state.breakingNews = []
                        state.headlines = headlines
                        state.isLoading = false
                        state.currentPage = 1
                        state.hasMorePages = headlines.count >= 20
                        state.hasLoadedInitialData = true
                    }
                }
                .store(in: &cancellables)
        } else {
            // "All" tab: fetch both breaking news and headlines
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
    }

    private func loadMoreHeadlines() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        // NewsAPI free tier has best coverage for US
        let country = "us"
        let nextPage = currentState.currentPage + 1
        let selectedCategory = currentState.selectedCategory

        let headlinesPublisher: AnyPublisher<[Article], Error>
        if let category = selectedCategory {
            headlinesPublisher = newsService.fetchTopHeadlines(category: category, country: country, page: nextPage)
        } else {
            headlinesPublisher = newsService.fetchTopHeadlines(country: country, page: nextPage)
        }

        headlinesPublisher
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
        // Invalidate cache on refresh to ensure fresh data
        if let cachingService = newsService as? CachingNewsService {
            cachingService.invalidateCache()
        }

        updateState { state in
            state.isRefreshing = true
            state.breakingNews = []
            state.headlines = []
            state.error = nil
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
        }

        // Reload followed topics
        loadFollowedTopics()

        let country = "us"
        let selectedCategory = currentState.selectedCategory

        // When a category is selected, only fetch headlines for that category
        if let category = selectedCategory {
            newsService.fetchTopHeadlines(category: category, country: country, page: 1)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isRefreshing = false
                            state.error = error.localizedDescription
                        }
                    }
                } receiveValue: { [weak self] headlines in
                    self?.updateState { state in
                        state.breakingNews = []
                        state.headlines = headlines
                        state.isRefreshing = false
                        state.currentPage = 1
                        state.hasMorePages = headlines.count >= 20
                        state.hasLoadedInitialData = true
                    }
                }
                .store(in: &cancellables)
        } else {
            // "All" tab: fetch both breaking news and headlines
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

    private func handleSelectCategory(_ category: NewsCategory?) {
        // Skip if already on this category
        guard category != currentState.selectedCategory else { return }

        updateState { state in
            state.selectedCategory = category
            state.headlines = []
            state.breakingNews = []
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
            state.isLoading = true
            state.error = nil
        }

        let country = "us"

        if let category {
            // Fetch category-filtered headlines
            newsService.fetchTopHeadlines(category: category, country: country, page: 1)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                    }
                } receiveValue: { [weak self] headlines in
                    self?.updateState { state in
                        state.headlines = headlines
                        state.isLoading = false
                        state.currentPage = 1
                        state.hasMorePages = headlines.count >= 20
                        state.hasLoadedInitialData = true
                    }
                }
                .store(in: &cancellables)
        } else {
            // "All" tab: fetch both breaking news and headlines
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
                let allArticles = breaking + headlines
                WidgetDataManager.shared.saveArticlesForWidget(allArticles)
            }
            .store(in: &cancellables)
        }
    }

    private func loadFollowedTopics() {
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service("Failed to load followed topics: \(error)", level: .warning)
                    }
                },
                receiveValue: { [weak self] preferences in
                    self?.updateState { state in
                        state.followedTopics = preferences.followedTopics
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func saveToReadingHistory(_ article: Article) {
        trackBackgroundTask { [weak self] in
            guard let self else { return }
            try? await storageService.saveReadingHistory(article)
        }
    }

    private func toggleBookmark(_ article: Article) {
        trackBackgroundTask { [weak self] in
            guard let self else { return }
            let isBookmarked = await storageService.isBookmarked(article.id)
            if isBookmarked {
                try? await storageService.deleteArticle(article)
            } else {
                try? await storageService.saveArticle(article)
            }
        }
    }

    /// Safely tracks and auto-removes background tasks with proper cleanup on deinit.
    /// Uses detached task for background work, tracks completion on MainActor.
    private func trackBackgroundTask(_ operation: @escaping @Sendable () async -> Void) {
        let task = Task.detached {
            await operation()
        }
        backgroundTasks.insert(task)

        Task { @MainActor [weak self] in
            _ = await task.result
            self?.backgroundTasks.remove(task)
        }
    }

    deinit {
        // Cancel all pending tasks on deallocation
        for task in backgroundTasks {
            task.cancel()
        }
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
