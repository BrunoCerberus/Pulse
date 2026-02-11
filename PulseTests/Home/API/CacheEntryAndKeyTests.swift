import Combine
import Foundation
@testable import Pulse
import Testing

// MARK: - Cache Entry Tests

@Suite("CacheEntry Tests")
struct CacheEntryTests {
    @Test("CacheEntry isExpired returns false when within TTL")
    func cacheEntryNotExpired() {
        let entry = CacheEntry(data: "test", timestamp: Date())
        #expect(!entry.isExpired(ttl: 60))
    }

    @Test("CacheEntry isExpired returns true when past TTL")
    func cacheEntryExpired() {
        let pastTimestamp = Date().addingTimeInterval(-61)
        let entry = CacheEntry(data: "test", timestamp: pastTimestamp)
        #expect(entry.isExpired(ttl: 60))
    }

    @Test("CacheEntry isExpired returns true exactly at TTL boundary")
    func cacheEntryAtBoundary() {
        let pastTimestamp = Date().addingTimeInterval(-60)
        let entry = CacheEntry(data: "test", timestamp: pastTimestamp)
        #expect(entry.isExpired(ttl: 60))
    }
}

// MARK: - Cache Key Tests

@Suite("NewsCacheKey Tests")
struct NewsCacheKeyTests {
    @Test("Cache keys generate unique string keys")
    func uniqueStringKeys() {
        let key1 = NewsCacheKey.breakingNews(country: "us")
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key3 = NewsCacheKey.topHeadlines(country: "us", page: 2)
        let key4 = NewsCacheKey.categoryHeadlines(category: .technology, country: "us", page: 1)
        let key5 = NewsCacheKey.article(id: "test-article")

        let allKeys = [key1.stringKey, key2.stringKey, key3.stringKey, key4.stringKey, key5.stringKey]
        let uniqueKeys = Set(allKeys)

        #expect(allKeys.count == uniqueKeys.count)
    }

    @Test("Same parameters produce same cache key")
    func sameParametersSameKey() {
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.topHeadlines(country: "us", page: 1)

        #expect(key1.stringKey == key2.stringKey)
        #expect(key1 == key2)
    }

    @Test("Different parameters produce different cache keys")
    func differentParametersDifferentKeys() {
        let key1 = NewsCacheKey.topHeadlines(country: "us", page: 1)
        let key2 = NewsCacheKey.topHeadlines(country: "uk", page: 1)
        let key3 = NewsCacheKey.topHeadlines(country: "us", page: 2)

        #expect(key1.stringKey != key2.stringKey)
        #expect(key1.stringKey != key3.stringKey)
    }
}
