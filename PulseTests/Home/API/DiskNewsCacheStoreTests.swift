import Foundation
@testable import Pulse
import Testing

@Suite("DiskNewsCacheStore Tests")
struct DiskNewsCacheStoreTests {
    let sut: DiskNewsCacheStore
    let testDirectory: URL

    init() {
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskNewsCacheStoreTests_\(UUID().uuidString)", isDirectory: true)
        sut = DiskNewsCacheStore(directory: testDirectory)
    }

    private func cleanup() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    // MARK: - Write/Read Tests

    @Test("Set and get article array")
    func setAndGetArticleArray() {
        defer { cleanup() }

        let articles = Article.mockArticles
        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let entry = CacheEntry(data: articles, timestamp: Date())

        sut.set(entry, for: key)

        let retrieved: CacheEntry<[Article]>? = sut.get(for: key)

        #expect(retrieved != nil)
        #expect(retrieved?.data.count == articles.count)
        #expect(retrieved?.data.first?.id == articles.first?.id)
    }

    @Test("Set and get single article")
    func setAndGetSingleArticle() {
        defer { cleanup() }

        let article = Article.mockArticles[0]
        let key = NewsCacheKey.article(id: article.id)
        let entry = CacheEntry(data: article, timestamp: Date())

        sut.set(entry, for: key)

        let retrieved: CacheEntry<Article>? = sut.get(for: key)

        #expect(retrieved != nil)
        #expect(retrieved?.data.id == article.id)
        #expect(retrieved?.data.title == article.title)
    }

    @Test("Get returns nil for nonexistent key")
    func getNonexistentKey() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "xx", page: 99)
        let result: CacheEntry<[Article]>? = sut.get(for: key)

        #expect(result == nil)
    }

    // MARK: - TTL Tests

    @Test("Timestamp is preserved for TTL checking")
    func timestampPreserved() throws {
        defer { cleanup() }

        let articles = Article.mockArticles
        let key = NewsCacheKey.breakingNews(language: "en", country: "us")
        let pastTimestamp = Date().addingTimeInterval(-3600)
        let entry = CacheEntry(data: articles, timestamp: pastTimestamp)

        sut.set(entry, for: key)

        let retrieved: CacheEntry<[Article]>? = sut.get(for: key)
        let unwrapped = try #require(retrieved)

        let timeDiff = Swift.abs(unwrapped.timestamp.timeIntervalSince(pastTimestamp))
        #expect(timeDiff < 1.0)
        #expect(unwrapped.isExpired(ttl: 1800))
    }

    // MARK: - Remove Tests

    @Test("Remove deletes specific cached entry")
    func removeSpecificEntry() {
        defer { cleanup() }

        let key1 = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let key2 = NewsCacheKey.breakingNews(language: "en", country: "us")
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())

        sut.set(entry, for: key1)
        sut.set(entry, for: key2)

        sut.remove(for: key1)

        let removed: CacheEntry<[Article]>? = sut.get(for: key1)
        let kept: CacheEntry<[Article]>? = sut.get(for: key2)

        #expect(removed == nil)
        #expect(kept != nil)
    }

    @Test("RemoveAll clears all entries")
    func removeAllEntries() {
        defer { cleanup() }

        let key1 = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let key2 = NewsCacheKey.breakingNews(language: "en", country: "us")
        let entry = CacheEntry(data: Article.mockArticles, timestamp: Date())

        sut.set(entry, for: key1)
        sut.set(entry, for: key2)

        sut.removeAll()

        let result1: CacheEntry<[Article]>? = sut.get(for: key1)
        let result2: CacheEntry<[Article]>? = sut.get(for: key2)

        #expect(result1 == nil)
        #expect(result2 == nil)
    }

    // MARK: - Corrupted File Tests

    @Test("Get returns nil for corrupted file")
    func corruptedFileReturnsNil() {
        defer { cleanup() }

        // Write garbage data to a cache file
        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let sanitized = key.stringKey.replacingOccurrences(of: "/", with: "_")
        let fileURL = testDirectory.appendingPathComponent(sanitized + ".json")

        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        try? Data("not valid json".utf8).write(to: fileURL)

        let result: CacheEntry<[Article]>? = sut.get(for: key)

        #expect(result == nil)
    }

    // MARK: - Overwrite Tests

    @Test("Setting same key overwrites previous data")
    func overwriteExistingEntry() {
        defer { cleanup() }

        let key = NewsCacheKey.topHeadlines(language: "en", country: "us", page: 1)
        let firstArticles = Array(Article.mockArticles.prefix(2))
        let secondArticles = Array(Article.mockArticles.prefix(4))

        sut.set(CacheEntry(data: firstArticles, timestamp: Date()), for: key)
        sut.set(CacheEntry(data: secondArticles, timestamp: Date()), for: key)

        let retrieved: CacheEntry<[Article]>? = sut.get(for: key)

        #expect(retrieved?.data.count == 4)
    }

    // MARK: - File Protection Migration Tests

    @Test("Init walks pre-existing files without corrupting them")
    func initWalksExistingFilesWithoutCorruption() throws {
        // Coverage target: `applyCompleteProtection(to:)` enumerates the
        // directory and re-applies `.complete` to every entry. We can't
        // assert the protection class itself on the simulator —
        // `attributesOfItem(atPath:)` doesn't expose `protectionKey` there —
        // but we *can* prove the loop runs by planting files first and
        // confirming they survive intact (instead of, say, being deleted or
        // truncated by a buggy migration).
        let migrationDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskNewsCacheStore_Migration_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: migrationDirectory) }

        try FileManager.default.createDirectory(
            at: migrationDirectory,
            withIntermediateDirectories: true
        )

        let legacyFile = migrationDirectory.appendingPathComponent("legacy.json")
        let secondFile = migrationDirectory.appendingPathComponent("other.json")
        try Data("legacy payload".utf8).write(to: legacyFile)
        try Data("second payload".utf8).write(to: secondFile)

        // Init triggers `applyCompleteProtection`, which iterates the
        // directory contents and calls `setAttributes` on each file.
        _ = DiskNewsCacheStore(directory: migrationDirectory)

        let firstPayload = try Data(contentsOf: legacyFile)
        let secondPayload = try Data(contentsOf: secondFile)
        #expect(String(data: firstPayload, encoding: .utf8) == "legacy payload")
        #expect(String(data: secondPayload, encoding: .utf8) == "second payload")
    }

    @Test("Empty cache directory init does not crash")
    func emptyDirectoryInitDoesNotCrash() {
        let emptyDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskNewsCacheStore_Empty_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: emptyDirectory) }

        _ = DiskNewsCacheStore(directory: emptyDirectory)

        #expect(FileManager.default.fileExists(atPath: emptyDirectory.path))
    }
}
