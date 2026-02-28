import Combine
import EntropyCore
import Foundation

/// A decorator that wraps a NewsService implementation and adds tiered caching.
///
/// Uses a two-level cache strategy:
/// - **L1 (memory)**: NSCache-based, 10-min TTL, cleared on memory warning
/// - **L2 (disk)**: File-based, 24-hour TTL, survives app restarts
///
/// When offline, serves stale data from either cache layer. When online,
/// network failures fall back to stale disk cache data.
final class CachingNewsService: NewsService {
    private let wrapped: NewsService
    private let memoryCacheStore: NewsCacheStore
    private let diskCacheStore: NewsCacheStore?
    private let networkMonitor: NetworkMonitorService?

    /// Creates a new caching news service.
    /// - Parameters:
    ///   - wrapped: The underlying news service to wrap
    ///   - cacheStore: The L1 memory cache store (defaults to LiveNewsCacheStore)
    ///   - diskCacheStore: The L2 disk cache store (defaults to DiskNewsCacheStore)
    ///   - networkMonitor: Network monitor for offline detection (optional)
    init(
        wrapping wrapped: NewsService,
        cacheStore: NewsCacheStore = LiveNewsCacheStore(),
        diskCacheStore: NewsCacheStore? = DiskNewsCacheStore(),
        networkMonitor: NetworkMonitorService? = nil
    ) {
        self.wrapped = wrapped
        memoryCacheStore = cacheStore
        self.diskCacheStore = diskCacheStore
        self.networkMonitor = networkMonitor
    }

    // MARK: - NewsService Implementation

    func fetchTopHeadlines(language: String, country: String, page: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.topHeadlines(language: language, country: country, page: page)
        return fetchWithTieredCache(
            key: cacheKey,
            label: "headlines (lang: \(language), country: \(country), page: \(page))"
        ) {
            self.wrapped.fetchTopHeadlines(language: language, country: country, page: page)
        }
    }

    func fetchTopHeadlines(
        category: NewsCategory,
        language: String,
        country: String,
        page: Int
    ) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.categoryHeadlines(
            language: language,
            category: category,
            country: country,
            page: page
        )
        return fetchWithTieredCache(
            key: cacheKey,
            label: "category headlines (lang: \(language), category: \(category.rawValue), page: \(page))"
        ) {
            self.wrapped.fetchTopHeadlines(category: category, language: language, country: country, page: page)
        }
    }

    func fetchBreakingNews(language: String, country: String) -> AnyPublisher<[Article], Error> {
        let cacheKey = NewsCacheKey.breakingNews(language: language, country: country)
        return fetchWithTieredCache(key: cacheKey, label: "breaking news (lang: \(language), country: \(country))") {
            self.wrapped.fetchBreakingNews(language: language, country: country)
        }
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        let cacheKey = NewsCacheKey.article(id: id)
        return fetchWithTieredCache(key: cacheKey, label: "article (id: \(id))") {
            self.wrapped.fetchArticle(id: id)
        }
    }

    // MARK: - Cache Management

    /// Invalidates L1 memory cache for the given keys only.
    /// Disk cache is preserved as offline fallback.
    func invalidateCache(for keys: [NewsCacheKey]) {
        for key in keys {
            memoryCacheStore.remove(for: key)
        }
        Logger.shared.service("L1 cache invalidated for \(keys.count) key(s)", level: .debug)
    }

    /// Invalidates all L1 memory cache.
    /// Disk cache is preserved as offline fallback.
    func invalidateCache() {
        memoryCacheStore.removeAll()
        Logger.shared.service("L1 cache invalidated", level: .debug)
    }

    /// Invalidates both L1 (memory) and L2 (disk) caches.
    /// Used during sign-out to remove all cached user data.
    func invalidateAllCaches() {
        memoryCacheStore.removeAll()
        diskCacheStore?.removeAll()
        Logger.shared.service("All caches invalidated (L1 + L2)", level: .debug)
    }

    // MARK: - Tiered Cache Logic

    /// Generic tiered cache fetch:
    /// 1. L1 hit (non-expired) → return immediately
    /// 2. L2 hit (non-expired) → promote to L1, return
    /// 3. Offline: serve stale from L1 or L2; if nothing → PulseError.offlineNoCache
    /// 4. Online: network fetch → write-through L1+L2; on failure → stale L2 fallback
    private func fetchWithTieredCache<T>(
        key: NewsCacheKey,
        label: String,
        networkFetch: @escaping () -> AnyPublisher<T, Error>
    ) -> AnyPublisher<T, Error> {
        // 1. Check L1 (memory) cache
        if let cached: CacheEntry<T> = memoryCacheStore.get(for: key),
           !cached.isExpired(ttl: NewsCacheTTL.default)
        {
            Logger.shared.service("L1 cache hit for \(label)", level: .debug)
            return Just(cached.data).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        // 2. Check L2 (disk) cache
        if let diskCached: CacheEntry<T> = diskCacheStore?.get(for: key),
           !diskCached.isExpired(ttl: DiskNewsCacheStore.diskTTL)
        {
            Logger.shared.service("L2 cache hit for \(label)", level: .debug)
            memoryCacheStore.set(diskCached, for: key)
            return Just(diskCached.data).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        // 3. If offline: serve stale data or fail
        if networkMonitor?.isConnected == false {
            // Try stale L1
            if let staleL1: CacheEntry<T> = memoryCacheStore.get(for: key) {
                Logger.shared.service("Offline: serving stale L1 for \(label)", level: .debug)
                return Just(staleL1.data)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            // Try stale L2 (expired but better than nothing)
            if let staleL2: CacheEntry<T> = diskCacheStore?.get(for: key) {
                Logger.shared.service("Offline: serving stale L2 for \(label)", level: .debug)
                return Just(staleL2.data)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            Logger.shared.service("Offline: no cache for \(label)", level: .debug)
            return Fail(error: PulseError.offlineNoCache)
                .eraseToAnyPublisher()
        }

        // 4. Online: fetch from network, write-through to both caches
        Logger.shared.service("Cache miss for \(label)", level: .debug)
        return networkFetch()
            .handleEvents(receiveOutput: { [weak self] data in
                let entry = CacheEntry(data: data, timestamp: Date())
                self?.memoryCacheStore.set(entry, for: key)
                self?.diskCacheStore?.set(entry, for: key)
            })
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                // On network failure, fall back to stale disk cache
                if let staleL2: CacheEntry<T> = self?.diskCacheStore?.get(for: key) {
                    Logger.shared.service("Network error: serving stale L2 for \(label)", level: .debug)
                    return Just(staleL2.data)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
