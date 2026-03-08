import Combine
import Foundation
@testable import Pulse
import Testing

// MARK: - Disk Cache Corruption Tests

@Suite("Disk Cache Corruption Tests")
struct DiskCacheCorruptionTests {
    let sut: DiskNewsCacheStore
    let testDirectory: URL

    init() {
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CacheCorruption_\(UUID().uuidString)", isDirectory: true)
        sut = DiskNewsCacheStore(directory: testDirectory)
    }

    private func cleanup() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    @Test("Corrupted random bytes return nil gracefully")
    func corruptedRandomBytesReturnNil() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        writeRawBytes(Data([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0xFF]), for: key)

        let result: CacheEntry<[Article]>? = sut.get(for: key)
        #expect(result == nil)
    }

    @Test("Empty file returns nil gracefully")
    func emptyFileReturnsNil() {
        defer { cleanup() }

        let key = NewsCacheKey.breakingNews(language: "en", country: "us")
        writeRawBytes(Data(), for: key)

        let result: CacheEntry<[Article]>? = sut.get(for: key)
        #expect(result == nil)
    }

    @Test("Truncated JSON returns nil gracefully")
    func truncatedJSONReturnsNil() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let truncated = "{\"timestamp\":\"2026-01-01T00:00:00Z\",\"payload\":"
        writeRawBytes(Data(truncated.utf8), for: key)

        let result: CacheEntry<[Article]>? = sut.get(for: key)
        #expect(result == nil)
    }

    @Test("Valid wrapper with corrupted payload returns nil")
    func validWrapperCorruptedPayloadReturnsNil() throws {
        defer { cleanup() }

        // Write a structurally valid DiskCacheWrapper but with garbage payload
        let wrapper: [String: Any] = [
            "timestamp": Date().timeIntervalSinceReferenceDate,
            "payload": "bm90LXZhbGlkLWpzb24=", // base64 of "not-valid-json"
        ]
        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let jsonData = try JSONSerialization.data(withJSONObject: wrapper)
        writeRawBytes(jsonData, for: key)

        let result: CacheEntry<[Article]>? = sut.get(for: key)
        #expect(result == nil)
    }

    @Test("Overwrite with atomic write returns latest data")
    func overwriteReturnsLatestData() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let firstArticles = Array(Article.mockArticles.prefix(2))
        let secondArticles = Array(Article.mockArticles.prefix(4))

        sut.set(CacheEntry(data: firstArticles, timestamp: Date()), for: key)
        sut.set(CacheEntry(data: secondArticles, timestamp: Date()), for: key)

        let retrieved: CacheEntry<[Article]>? = sut.get(for: key)

        #expect(retrieved?.data.count == 4)
    }

    @Test("Requesting wrong type returns nil")
    func wrongTypeReturnsNil() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        sut.set(CacheEntry(data: Article.mockArticles, timestamp: Date()), for: key)

        // Try to get single Article when [Article] was stored
        let result: CacheEntry<Article>? = sut.get(for: key)
        #expect(result == nil)
    }

    // MARK: - Helpers

    private func writeRawBytes(_ data: Data, for key: NewsCacheKey) {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = key.stringKey.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "_" }
            .joined()
        let fileURL = testDirectory.appendingPathComponent(sanitized + ".json")

        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        try? data.write(to: fileURL)
    }
}

// MARK: - Cache TTL Boundary Tests

@Suite("Cache TTL Boundary Tests")
struct CacheTTLBoundaryTests {
    @Test("L1 entry at exactly 10 minutes is expired")
    func l1EntryAtExactTTLIsExpired() {
        let timestamp = Date().addingTimeInterval(-NewsCacheTTL.default)
        let entry = CacheEntry(data: Article.mockArticles, timestamp: timestamp)

        #expect(entry.isExpired(ttl: NewsCacheTTL.default))
    }

    @Test("L1 entry at 9 minutes 59 seconds is not expired")
    func l1EntryJustBeforeTTLIsNotExpired() {
        let timestamp = Date().addingTimeInterval(-(NewsCacheTTL.default - 1))
        let entry = CacheEntry(data: Article.mockArticles, timestamp: timestamp)

        #expect(!entry.isExpired(ttl: NewsCacheTTL.default))
    }

    @Test("L2 entry at exactly 24 hours is expired")
    func l2EntryAtExactTTLIsExpired() {
        let timestamp = Date().addingTimeInterval(-DiskNewsCacheStore.diskTTL)
        let entry = CacheEntry(data: Article.mockArticles, timestamp: timestamp)

        #expect(entry.isExpired(ttl: DiskNewsCacheStore.diskTTL))
    }

    @Test("L2 entry at 23h 59m 59s is not expired")
    func l2EntryJustBeforeTTLIsNotExpired() {
        let timestamp = Date().addingTimeInterval(-(DiskNewsCacheStore.diskTTL - 1))
        let entry = CacheEntry(data: Article.mockArticles, timestamp: timestamp)

        #expect(!entry.isExpired(ttl: DiskNewsCacheStore.diskTTL))
    }

    @Test("Fresh entry is never expired")
    func freshEntryIsNotExpired() {
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())

        #expect(!entry.isExpired(ttl: NewsCacheTTL.default))
        #expect(!entry.isExpired(ttl: DiskNewsCacheStore.diskTTL))
    }
}

// MARK: - Concurrent Cache Access Tests

@Suite("Concurrent Cache Access Tests")
struct ConcurrentCacheAccessTests {
    @Test("Concurrent reads from DiskNewsCacheStore do not crash")
    func concurrentReadsDoNotCrash() async {
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CacheConcurrent_\(UUID().uuidString)", isDirectory: true)
        let store = DiskNewsCacheStore(directory: testDirectory)
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        store.set(CacheEntry(data: Article.mockArticles, timestamp: Date()), for: key)

        // Dispatch 10 concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    let _: CacheEntry<[Article]>? = store.get(for: key)
                }
            }
        }

        // If we get here without crash, the test passes
        let result: CacheEntry<[Article]>? = store.get(for: key)
        #expect(result != nil)
    }

    @Test("Concurrent write and read does not crash")
    func concurrentWriteAndReadDoesNotCrash() async {
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CacheConcurrentWR_\(UUID().uuidString)", isDirectory: true)
        let store = DiskNewsCacheStore(directory: testDirectory)
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for index in 0 ..< 5 {
                group.addTask {
                    let articles = Array(Article.mockArticles.prefix(index + 1))
                    store.set(CacheEntry(data: articles, timestamp: Date()), for: key)
                }
            }
            // Readers
            for _ in 0 ..< 5 {
                group.addTask {
                    let _: CacheEntry<[Article]>? = store.get(for: key)
                }
            }
        }

        // Should not crash; final state should be readable
        let result: CacheEntry<[Article]>? = store.get(for: key)
        #expect(result != nil)
    }
}

// MARK: - Malformed Network Response Tests

@Suite("Malformed Network Response Tests")
struct MalformedNetworkResponseTests {
    @Test("Empty array from network is cached and returned")
    func emptyArrayIsCachedAndReturned() async throws {
        let mockWrapped = MockNewsService()
        mockWrapped.topHeadlinesResult = .success([])
        let mockL1 = MockNewsCacheStore()
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyArray_\(UUID().uuidString)", isDirectory: true)
        let diskL2 = DiskNewsCacheStore(directory: testDirectory)
        let sut = CachingNewsService(
            wrapping: mockWrapped,
            cacheStore: mockL1,
            diskCacheStore: diskL2,
            networkMonitor: MockNetworkMonitorService(isConnected: true),
            networkResilienceEnabled: false
        )
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let result = try await awaitPublisher(
            sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
        )

        #expect(result.isEmpty)
        #expect(mockL1.setCallCount > 0, "Empty array should still be cached")
    }

    @Test("Network resilience disabled means single attempt on failure")
    func networkResilienceDisabledSingleAttempt() async {
        let mockWrapped = MockNewsService()
        mockWrapped.topHeadlinesResult = .failure(URLError(.timedOut))
        let sut = CachingNewsService(
            wrapping: mockWrapped,
            cacheStore: MockNewsCacheStore(),
            diskCacheStore: nil,
            networkMonitor: MockNetworkMonitorService(isConnected: true),
            networkResilienceEnabled: false
        )

        do {
            _ = try await awaitPublisher(
                sut.fetchTopHeadlines(language: "en", country: "us", page: 1)
            )
            Issue.record("Expected error")
        } catch {
            // Only one call should have been made (no retries)
            #expect(mockWrapped.fetchedTopHeadlinesLanguages.count == 1)
        }
    }

    // MARK: - Helpers

    private func awaitPublisher<T>(_ publisher: AnyPublisher<T, Error>) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}
