import Combine
import EntropyCore
import Foundation

// MARK: - Data Loading Helpers

/// Extension containing data loading helpers to reduce function body length in HomeDomainInteractor.
extension HomeDomainInteractor {
    // MARK: - Category-filtered Headlines

    /// Fetches headlines for a specific category and updates state.
    func fetchCategoryHeadlines(
        category: NewsCategory,
        country: String,
        page: Int,
        isRefreshing _: Bool = false
    ) -> AnyPublisher<Void, Never> {
        newsService.fetchTopHeadlines(category: category, language: preferredLanguage, country: country, page: page)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] headlines in
                    // Filter out media items (videos/podcasts) - they belong in MediaView
                    let filteredHeadlines = headlines.filter { !$0.isMedia }
                    self?.updateState { state in
                        state.breakingNews = []
                        state.headlines = filteredHeadlines
                        state.isLoading = false
                        state.isRefreshing = false
                        state.currentPage = page
                        // Use unfiltered count for pagination: backend page size determines if more exist.
                        // Filtering happens client-side; backend doesn't know about media exclusion.
                        state.hasMorePages = headlines.count >= 20
                        state.hasLoadedInitialData = true
                        state.isOfflineError = false
                    }
                },
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.isRefreshing = false
                            state.error = error.localizedDescription
                            state.isOfflineError = error.isOfflineError
                        }
                    }
                }
            )
            .map { _ in () }
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }

    // MARK: - All Headlines (Breaking + Top)

    /// Fetches both breaking news and headlines for the "All" tab and updates state.
    func fetchAllHeadlines(country: String, page: Int, isRefreshing _: Bool = false) -> AnyPublisher<Void, Never> {
        Publishers.Zip(
            newsService.fetchBreakingNews(language: preferredLanguage, country: country),
            newsService.fetchTopHeadlines(language: preferredLanguage, country: country, page: page)
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveOutput: { [weak self] breaking, headlines in
                guard let self else { return }
                // Filter out media items (videos/podcasts) - they belong in MediaView
                let filteredBreaking = breaking.filter { !$0.isMedia }
                let filteredHeadlines = headlines.filter { !$0.isMedia }
                let deduplicated = self.deduplicateArticles(filteredHeadlines, excluding: filteredBreaking)
                self.updateState { state in
                    state.breakingNews = filteredBreaking
                    state.headlines = deduplicated
                    state.isLoading = false
                    state.isRefreshing = false
                    state.currentPage = page
                    // Use unfiltered count for pagination: backend page size determines if more exist.
                    // Filtering happens client-side; backend doesn't know about media exclusion.
                    state.hasMorePages = headlines.count >= 20
                    state.hasLoadedInitialData = true
                    state.isOfflineError = false
                }
                // Update widget with latest headlines (excluding media)
                let allArticles = filteredBreaking + filteredHeadlines
                WidgetDataManager.shared.saveArticlesForWidget(allArticles)
            },
            receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.isLoading = false
                        state.isRefreshing = false
                        state.error = error.localizedDescription
                        state.isOfflineError = error.isOfflineError
                    }
                }
            }
        )
        .map { _, _ in () }
        .replaceError(with: ())
        .eraseToAnyPublisher()
    }

    // MARK: - State Reset Helpers

    /// Resets state for a refresh operation.
    func resetStateForRefresh() {
        // Invalidate only the keys being refreshed instead of the entire cache
        if let cachingService = newsService as? CachingNewsService {
            let country = "us"
            let language = preferredLanguage
            var keysToInvalidate: [NewsCacheKey] = [
                .breakingNews(language: language, country: country),
                .topHeadlines(language: language, country: country, page: 1),
            ]
            if let category = currentState.selectedCategory {
                keysToInvalidate.append(.categoryHeadlines(
                    language: language,
                    category: category,
                    country: country,
                    page: 1
                ))
            }
            cachingService.invalidateCache(for: keysToInvalidate)
        }

        updateState { state in
            state.isRefreshing = true
            // Preserve existing content so it remains visible if refresh fails (e.g., offline)
            state.error = nil
            state.isOfflineError = false
            state.currentPage = 1
            state.hasMorePages = true
        }
    }

    /// Resets state for a category change.
    func resetStateForCategoryChange(to category: NewsCategory?) {
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
    }

    // MARK: - Internal Helpers (exposed for extension)

    /// Removes articles that already exist in the exclusion list.
    func deduplicateArticles(_ articles: [Article], excluding: [Article]) -> [Article] {
        let excludeIDs = Set(excluding.map { $0.id })
        return articles.filter { !excludeIDs.contains($0.id) }
    }

    /// Updates state using a transform closure.
    func updateState(_ transform: (inout HomeDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    // MARK: - Preferences Helpers

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
                    self.updateState { state in
                        state.followedTopics = updatedPreferences.followedTopics
                    }
                    self.savePreferences(updatedPreferences)
                }
            )
            .store(in: &cancellables)
    }

    func savePreferences(_ preferences: UserPreferences) {
        settingsService.savePreferences(preferences)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service("Failed to save preferences: \(error)", level: .warning)
                    }
                },
                receiveValue: { [weak self] in
                    // Mark as local change so our notification observer skips the redundant re-fetch
                    self?.isLocalPreferenceChange = true
                    // Notify other components that preferences changed
                    NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
                }
            )
            .store(in: &cancellables)
    }

    func setEditingTopics(_ editing: Bool) {
        updateState { state in
            state.isEditingTopics = editing
        }
    }
}
