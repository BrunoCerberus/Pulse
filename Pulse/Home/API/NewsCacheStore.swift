import Foundation
import UIKit

// MARK: - Cache Entry

/// A generic cache entry that holds data along with its timestamp for TTL validation.
struct CacheEntry<T> {
    let data: T
    let timestamp: Date

    /// Checks if the cache entry has expired based on the given TTL.
    /// - Parameter ttl: Time-to-live in seconds
    /// - Returns: `true` if the entry has expired, `false` otherwise
    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) >= ttl
    }
}

// MARK: - Cache Key

/// Represents the different types of cacheable news content with their unique identifiers.
enum NewsCacheKey: Hashable {
    case breakingNews(country: String)
    case topHeadlines(country: String, page: Int)
    case categoryHeadlines(category: NewsCategory, country: String, page: Int)
    case article(id: String)

    /// String representation of the cache key for NSCache storage.
    var stringKey: String {
        switch self {
        case let .breakingNews(country):
            return "breaking_\(country)"
        case let .topHeadlines(country, page):
            return "headlines_\(country)_p\(page)"
        case let .categoryHeadlines(category, country, page):
            return "category_\(category.rawValue)_\(country)_p\(page)"
        case let .article(id):
            return "article_\(id)"
        }
    }
}

// MARK: - Cache TTL Configuration

/// Defines time-to-live durations for different types of cached content.
enum NewsCacheTTL {
    /// Breaking news has high freshness expectation (5 minutes)
    static let breakingNews: TimeInterval = 5 * 60

    /// Page 1 headlines balance freshness vs API savings (10 minutes)
    static let headlinesPage1: TimeInterval = 10 * 60

    /// Page 2+ headlines are less critical (30 minutes)
    static let headlinesPageN: TimeInterval = 30 * 60

    /// Category headlines similar to page 1 (10 minutes)
    static let categoryHeadlines: TimeInterval = 10 * 60

    /// Individual articles rarely change (60 minutes)
    static let article: TimeInterval = 60 * 60

    /// Returns the appropriate TTL for a given cache key.
    static func ttl(for key: NewsCacheKey) -> TimeInterval {
        switch key {
        case .breakingNews:
            return breakingNews
        case let .topHeadlines(_, page):
            return page == 1 ? headlinesPage1 : headlinesPageN
        case .categoryHeadlines:
            return categoryHeadlines
        case .article:
            return article
        }
    }
}

// MARK: - Cache Store Protocol

/// Protocol defining the interface for news cache storage.
protocol NewsCacheStore: AnyObject {
    /// Retrieves a cached entry for the given key.
    /// - Parameter key: The cache key to look up
    /// - Returns: The cached entry if it exists, nil otherwise
    func get<T>(for key: NewsCacheKey) -> CacheEntry<T>?

    /// Stores a cache entry for the given key.
    /// - Parameters:
    ///   - entry: The cache entry to store
    ///   - key: The cache key to associate with the entry
    func set<T>(_ entry: CacheEntry<T>, for key: NewsCacheKey)

    /// Removes a cached entry for the given key.
    /// - Parameter key: The cache key to remove
    func remove(for key: NewsCacheKey)

    /// Removes all cached entries.
    func removeAll()

    /// Removes cached entries matching a predicate.
    /// - Parameter predicate: A closure that returns true for keys to remove
    func removeMatching(_ predicate: (NewsCacheKey) -> Bool)
}

// MARK: - Live Cache Store Implementation

/// NSCache-based implementation of NewsCacheStore with memory-aware limits.
final class LiveNewsCacheStore: NewsCacheStore {
    /// Internal wrapper to allow storing any type in NSCache
    private final class CacheEntryWrapper: NSObject {
        let entry: Any

        init(entry: Any) {
            self.entry = entry
        }
    }

    private let cache: NSCache<NSString, CacheEntryWrapper>
    private var memoryWarningObserver: NSObjectProtocol?

    /// Tracks active cache keys for selective invalidation
    private var activeKeys = Set<NewsCacheKey>()
    private let keysLock = NSLock()

    init() {
        cache = NSCache()
        // Limit to 100 entries (reasonable for news content)
        cache.countLimit = 100
        // Limit total cost to 50MB (rough estimate)
        cache.totalCostLimit = 50 * 1024 * 1024

        // Clear cache on memory warning
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeAll()
            Logger.shared.service("News cache cleared due to memory warning", level: .info)
        }
    }

    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func get<T>(for key: NewsCacheKey) -> CacheEntry<T>? {
        let nsKey = key.stringKey as NSString
        guard let wrapper = cache.object(forKey: nsKey),
              let entry = wrapper.entry as? CacheEntry<T>
        else {
            return nil
        }
        return entry
    }

    func set<T>(_ entry: CacheEntry<T>, for key: NewsCacheKey) {
        let nsKey = key.stringKey as NSString
        let wrapper = CacheEntryWrapper(entry: entry)
        // Estimate cost based on data type
        let cost = estimateCost(for: entry.data)
        cache.setObject(wrapper, forKey: nsKey, cost: cost)

        // Track the key for selective invalidation
        keysLock.withLock {
            activeKeys.insert(key)
        }
    }

    func remove(for key: NewsCacheKey) {
        let nsKey = key.stringKey as NSString
        cache.removeObject(forKey: nsKey)

        keysLock.withLock {
            activeKeys.remove(key)
        }
    }

    func removeAll() {
        cache.removeAllObjects()

        keysLock.withLock {
            activeKeys.removeAll()
        }
    }

    func removeMatching(_ predicate: (NewsCacheKey) -> Bool) {
        // Collect keys to remove under lock to avoid holding lock during cache operations
        let keysToRemove = keysLock.withLock {
            activeKeys.filter(predicate)
        }

        // Remove matching entries
        for key in keysToRemove {
            remove(for: key)
        }

        Logger.shared.service("Selectively removed \(keysToRemove.count) cache entries", level: .debug)
    }

    /// Estimates memory cost for cache entries to help NSCache manage memory.
    private func estimateCost(for data: Any) -> Int {
        switch data {
        case let articles as [Article]:
            // Rough estimate: ~1KB per article
            return articles.count * 1024
        case _ as Article:
            return 1024
        default:
            return 1024
        }
    }
}
