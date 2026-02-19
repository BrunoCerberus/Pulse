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
    let settingsService: SettingsService
    private let analyticsService: AnalyticsService?
    let stateSubject = CurrentValueSubject<HomeDomainState, Never>(.initial)
    var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()
    var isLocalPreferenceChange = false
    private(set) var preferredLanguage: String = "en"

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

        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        // Observe preference changes to update followed topics when returning from Settings
        NotificationCenter.default.publisher(for: .userPreferencesDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Skip re-fetch when the change originated from our own toggleTopic
                if self.isLocalPreferenceChange {
                    self.isLocalPreferenceChange = false
                    return
                }
                self.loadFollowedTopicsAndCheckLanguage()
            }
            .store(in: &cancellables)
    }

    func dispatch(action: HomeDomainAction) {
        if handleLoadingActions(action) {
            return
        }
        if handleArticleActions(action) {
            return
        }
        handlePreferenceActions(action)
    }

    private func handleLoadingActions(_ action: HomeDomainAction) -> Bool {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .loadMoreHeadlines:
            loadMoreHeadlines()
        case .refresh:
            refresh()
        case let .selectCategory(category):
            handleSelectCategory(category)
        default:
            return false
        }
        return true
    }

    private func handleArticleActions(_ action: HomeDomainAction) -> Bool {
        switch action {
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
        default:
            return false
        }
        return true
    }

    private func handlePreferenceActions(_ action: HomeDomainAction) {
        switch action {
        case let .toggleTopic(topic):
            toggleTopic(topic)
        case let .setEditingTopics(editing):
            setEditingTopics(editing)
        default:
            break
        }
    }

    private func findArticle(by id: String) -> Article? {
        currentState.breakingNews.first { $0.id == id }
            ?? currentState.headlines.first { $0.id == id }
    }

    deinit {
        // Cancel all pending tasks on deallocation
        for task in backgroundTasks {
            task.cancel()
        }
    }

    // deduplicateArticles and updateState moved to HomeDomainInteractor+DataLoading.swift
}

// MARK: - Home Data Flow

private extension HomeDomainInteractor {
    func loadInitialData() {
        loadFollowedTopics()
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        analyticsService?.logEvent(.screenView(screen: .home))

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        fetchHeadlinesForCurrentCategory(page: 1)
    }

    func loadMoreHeadlines() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        // NewsAPI free tier has best coverage for US
        let country = "us"
        let language = preferredLanguage
        let nextPage = currentState.currentPage + 1
        let selectedCategory = currentState.selectedCategory

        let headlinesPublisher: AnyPublisher<[Article], Error>
        if let category = selectedCategory {
            headlinesPublisher = newsService.fetchTopHeadlines(
                category: category,
                language: language,
                country: country,
                page: nextPage
            )
        } else {
            headlinesPublisher = newsService.fetchTopHeadlines(language: language, country: country, page: nextPage)
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
                    // Cap headlines to prevent unbounded memory growth during infinite scroll
                    let maxHeadlines = 500
                    if state.headlines.count > maxHeadlines {
                        state.headlines.removeFirst(state.headlines.count - maxHeadlines)
                    }
                    state.isLoadingMore = false
                    state.currentPage = nextPage
                    // Use unfiltered count for pagination: backend page size determines if more exist.
                    // Filtering happens client-side; backend doesn't know about media exclusion.
                    state.hasMorePages = articles.count >= 20
                }
            }
            .store(in: &cancellables)
    }

    func refresh() {
        resetStateForRefresh()
        loadFollowedTopics()
        fetchHeadlinesForCurrentCategory(page: 1, isRefreshing: true)
    }

    func fetchHeadlinesForCurrentCategory(page: Int, isRefreshing: Bool = false) {
        let country = "us"
        if let category = currentState.selectedCategory {
            fetchCategoryHeadlines(category: category, country: country, page: page, isRefreshing: isRefreshing)
                .sink { _ in }
                .store(in: &cancellables)
        } else {
            fetchAllHeadlines(country: country, page: page, isRefreshing: isRefreshing)
                .sink { _ in }
                .store(in: &cancellables)
        }
    }

    func handleSelectCategory(_ category: NewsCategory?) {
        guard category != currentState.selectedCategory else { return }
        if let category {
            analyticsService?.logEvent(.categorySelected(category: category.rawValue))
        }
        resetStateForCategoryChange(to: category)
        fetchHeadlinesForCurrentCategory(page: 1)
    }
}

// MARK: - Home Article Actions

private extension HomeDomainInteractor {
    func selectArticle(_ article: Article) {
        analyticsService?.logEvent(.articleOpened(source: .home))
        updateState { state in
            state.selectedArticle = article
        }
    }

    func clearSelectedArticle() {
        updateState { state in
            state.selectedArticle = nil
        }
    }

    func shareArticle(_ article: Article) {
        analyticsService?.logEvent(.articleShared)
        updateState { state in
            state.articleToShare = article
        }
    }

    func clearArticleToShare() {
        updateState { state in
            state.articleToShare = nil
        }
    }

    func toggleBookmark(_ article: Article) {
        trackBackgroundTask { [weak self] in
            guard let self else { return }
            let isBookmarked = await storageService.isBookmarked(article.id)
            if isBookmarked {
                try? await storageService.deleteArticle(article)
                await MainActor.run { self.analyticsService?.logEvent(.articleUnbookmarked) }
            } else {
                try? await storageService.saveArticle(article)
                await MainActor.run { self.analyticsService?.logEvent(.articleBookmarked) }
            }
        }
    }

    /// Safely tracks and auto-removes background tasks with proper cleanup on deinit.
    func trackBackgroundTask(_ operation: @escaping @Sendable () async -> Void) {
        var task: Task<Void, Never>!
        task = Task.detached { [weak self] in
            await operation()
            guard let strongSelf = self else { return }
            _ = await MainActor.run {
                strongSelf.backgroundTasks.remove(task)
            }
        }
        backgroundTasks.insert(task)
    }
}

// MARK: - Home Preferences

private extension HomeDomainInteractor {
    func loadFollowedTopics() {
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service("Failed to load followed topics: \(error)", level: .warning)
                    }
                },
                receiveValue: { [weak self] preferences in
                    guard let self else { return }
                    self.preferredLanguage = preferences.preferredLanguage
                    self.updateState { state in
                        state.followedTopics = preferences.followedTopics
                    }
                }
            )
            .store(in: &cancellables)
    }

    /// Loads followed topics and checks if language changed, triggering a full reload if so.
    func loadFollowedTopicsAndCheckLanguage() {
        let previousLanguage = preferredLanguage
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service("Failed to load preferences: \(error)", level: .warning)
                    }
                },
                receiveValue: { [weak self] preferences in
                    guard let self else { return }
                    self.preferredLanguage = preferences.preferredLanguage
                    self.updateState { state in
                        state.followedTopics = preferences.followedTopics
                    }
                    // If language changed, invalidate cache and do a full reload
                    if previousLanguage != self.preferredLanguage {
                        if let cachingService = self.newsService as? CachingNewsService {
                            cachingService.invalidateCache()
                        }
                        self.resetStateForCategoryChange(to: self.currentState.selectedCategory)
                        self.fetchHeadlinesForCurrentCategory(page: 1)
                    }
                }
            )
            .store(in: &cancellables)
    }

    func toggleTopic(_ topic: NewsCategory) {
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service("Failed to fetch preferences for toggle: \(error)", level: .warning)
                    }
                },
                receiveValue: { [weak self] preferences in
                    guard let self else { return }
                    var updatedPreferences = preferences
                    if updatedPreferences.followedTopics.contains(topic) {
                        updatedPreferences.followedTopics.removeAll { $0 == topic }
                    } else {
                        updatedPreferences.followedTopics.append(topic)
                    }
                    // Update local state immediately to avoid redundant re-fetch
                    self.updateState { state in
                        state.followedTopics = updatedPreferences.followedTopics
                    }
                    self.savePreferences(updatedPreferences)
                }
            )
            .store(in: &cancellables)
    }
}
