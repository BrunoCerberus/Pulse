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
final class HomeDomainInteractor: CombineInteractor {
    typealias DomainState = HomeDomainState
    typealias DomainAction = HomeDomainAction

    let newsService: NewsService
    private let storageService: StorageService
    private let settingsService: SettingsService
    let stateSubject = CurrentValueSubject<HomeDomainState, Never>(.initial)
    var cancellables = Set<AnyCancellable>()
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

        // Observe preference changes to update followed topics when returning from Settings
        NotificationCenter.default.publisher(for: .userPreferencesDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadFollowedTopics()
            }
            .store(in: &cancellables)
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
        loadFollowedTopics()
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        let country = "us"
        if let category = currentState.selectedCategory {
            fetchCategoryHeadlines(category: category, country: country, page: 1)
                .sink { _ in }
                .store(in: &cancellables)
        } else {
            fetchAllHeadlines(country: country, page: 1)
                .sink { _ in }
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
                    // Filter out media items (videos/podcasts) - they belong in MediaView
                    let nonMediaArticles = articles.filter { !$0.isMedia }
                    let existingIDs = Set(state.headlines.map { $0.id } + state.breakingNews.map { $0.id })
                    let newArticles = nonMediaArticles.filter { !existingIDs.contains($0.id) }
                    state.headlines.append(contentsOf: newArticles)
                    state.isLoadingMore = false
                    state.currentPage = nextPage
                    // Use unfiltered count for pagination: backend page size determines if more exist.
                    // Filtering happens client-side; backend doesn't know about media exclusion.
                    state.hasMorePages = articles.count >= 20
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        resetStateForRefresh()
        loadFollowedTopics()

        let country = "us"
        if let category = currentState.selectedCategory {
            fetchCategoryHeadlines(category: category, country: country, page: 1, isRefreshing: true)
                .sink { _ in }
                .store(in: &cancellables)
        } else {
            fetchAllHeadlines(country: country, page: 1, isRefreshing: true)
                .sink { _ in }
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
        guard category != currentState.selectedCategory else { return }
        resetStateForCategoryChange(to: category)

        let country = "us"
        if let category {
            fetchCategoryHeadlines(category: category, country: country, page: 1)
                .sink { _ in }
                .store(in: &cancellables)
        } else {
            fetchAllHeadlines(country: country, page: 1)
                .sink { _ in }
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

    // deduplicateArticles and updateState moved to HomeDomainInteractor+DataLoading.swift
}
