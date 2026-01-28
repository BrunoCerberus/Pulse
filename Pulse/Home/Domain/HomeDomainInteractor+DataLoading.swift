import Combine
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
        newsService.fetchTopHeadlines(category: category, country: country, page: page)
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
                    }
                },
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.isRefreshing = false
                            state.error = error.localizedDescription
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
            newsService.fetchBreakingNews(country: country),
            newsService.fetchTopHeadlines(country: country, page: page)
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
}
