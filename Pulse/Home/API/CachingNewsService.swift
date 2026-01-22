import Combine
import Foundation

/// A decorator that wraps a NewsService implementation and adds caching functionality.
///
/// This service checks the cache before making network requests and stores responses
/// in the cache for future use. Each content type has a configurable TTL defined in
/// `NewsCacheTTL`.
///
/// Usage:
/// ```swift
/// let cachingService = CachingNewsService(wrapping: LiveNewsService())
/// serviceLocator.register(NewsService.self, instance: cachingService)
/// ```
final class CachingNewsService: NewsService {
    private let wrapped: NewsService
    private let cacheStore: NewsCacheStore

    /// Creates a new caching news service.
    /// - Parameters:
    ///   - wrapped: The underlying news service to wrap
    ///   - cacheStore: The cache store to use (defaults to LiveNewsCacheStore)
    init(wrapping wrapped: NewsService, cacheStore: NewsCacheStore = LiveNewsCacheStore()) {
        self.wrapped = wrapped
        self.cacheStore = cacheStore
    }

    // MARK: - NewsService Implementation

    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.topHeadlines(country: country, page: page)

        // Check cache first
        if let cached: CacheEntry<[Article]> = cacheStore.get(for: cacheKey),
           !cached.isExpired(ttl: NewsCacheTTL.default)
        {
            Logger.shared.service("Cache hit for headlines (country: \(country), page: \(page))", level: .debug)
            return Just(cached.data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Fetch from network and cache
        Logger.shared.service("Cache miss for headlines (country: \(country), page: \(page))", level: .debug)
        return wrapped.fetchTopHeadlines(country: country, page: page)
            .handleEvents(receiveOutput: { [weak self] articles in
                let entry = CacheEntry(data: articles, timestamp: Date())
                self?.cacheStore.set(entry, for: cacheKey)
            })
            .eraseToAnyPublisher()
    }

    func fetchTopHeadlines(category: NewsCategory, country: String, page: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.categoryHeadlines(category: category, country: country, page: page)

        // Check cache first
        if let cached: CacheEntry<[Article]> = cacheStore.get(for: cacheKey),
           !cached.isExpired(ttl: NewsCacheTTL.default)
        {
            Logger.shared.service(
                "Cache hit for category headlines (category: \(category.rawValue), page: \(page))",
                level: .debug
            )
            return Just(cached.data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Fetch from network and cache
        Logger.shared.service(
            "Cache miss for category headlines (category: \(category.rawValue), page: \(page))",
            level: .debug
        )
        return wrapped.fetchTopHeadlines(category: category, country: country, page: page)
            .handleEvents(receiveOutput: { [weak self] articles in
                let entry = CacheEntry(data: articles, timestamp: Date())
                self?.cacheStore.set(entry, for: cacheKey)
            })
            .eraseToAnyPublisher()
    }

    func fetchBreakingNews(country: String) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.breakingNews(country: country)

        // Check cache first
        if let cached: CacheEntry<[Article]> = cacheStore.get(for: cacheKey),
           !cached.isExpired(ttl: NewsCacheTTL.default)
        {
            Logger.shared.service("Cache hit for breaking news (country: \(country))", level: .debug)
            return Just(cached.data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Fetch from network and cache
        Logger.shared.service("Cache miss for breaking news (country: \(country))", level: .debug)
        return wrapped.fetchBreakingNews(country: country)
            .handleEvents(receiveOutput: { [weak self] articles in
                let entry = CacheEntry(data: articles, timestamp: Date())
                self?.cacheStore.set(entry, for: cacheKey)
            })
            .eraseToAnyPublisher()
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        let cacheKey = NewsCacheKey.article(id: id)

        // Check cache first
        if let cached: CacheEntry<Article> = cacheStore.get(for: cacheKey),
           !cached.isExpired(ttl: NewsCacheTTL.default)
        {
            Logger.shared.service("Cache hit for article (id: \(id))", level: .debug)
            return Just(cached.data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Fetch from network and cache
        Logger.shared.service("Cache miss for article (id: \(id))", level: .debug)
        return wrapped.fetchArticle(id: id)
            .handleEvents(receiveOutput: { [weak self] article in
                let entry = CacheEntry(data: article, timestamp: Date())
                self?.cacheStore.set(entry, for: cacheKey)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Cache Management

    /// Invalidates all cached data.
    ///
    /// Call this method when the user performs a pull-to-refresh action
    /// to ensure fresh data is fetched from the network.
    func invalidateCache() {
        cacheStore.removeAll()
        Logger.shared.service("News cache invalidated", level: .debug)
    }
}
