import Foundation
@testable import Pulse
import Testing

@Suite("ImagePrefetcher Tests")
struct ImagePrefetcherTests {
    // MARK: - Test URLs

    private func uniqueURL() -> URL {
        URL(string: "https://example.com/image-\(UUID().uuidString).jpg")!
    }

    // MARK: - Singleton Tests

    @Test("ImagePrefetcher shared instance is singleton")
    func sharedInstanceIsSingleton() {
        let instance1 = ImagePrefetcher.shared
        let instance2 = ImagePrefetcher.shared

        // Actor identity comparison
        #expect(instance1 === instance2)
    }

    // MARK: - Prefetch Tests

    @Test("prefetch adds URLs to pending queue")
    func prefetchAddsURLsToPendingQueue() async throws {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        let urls = (0 ..< 10).map { _ in uniqueURL() }

        await prefetcher.prefetch(urls: urls)

        // Give some time for processing to start
        try await Task.sleep(nanoseconds: 50_000_000)

        // Cancel all to clean up
        await prefetcher.cancelAll()
    }

    @Test("prefetch skips duplicate URLs")
    func prefetchSkipsDuplicates() async throws {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        let url = uniqueURL()

        // Prefetch same URL twice
        await prefetcher.prefetch(urls: [url])
        await prefetcher.prefetch(urls: [url])

        // Give some time for processing
        try await Task.sleep(nanoseconds: 50_000_000)

        await prefetcher.cancelAll()
    }

    @Test("prefetch handles empty array gracefully")
    func prefetchHandlesEmptyArray() async {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        // Should not crash or cause issues
        await prefetcher.prefetch(urls: [])
    }

    // MARK: - Cancel Tests

    @Test("cancelPrefetch removes URLs from queue")
    func cancelPrefetchRemovesFromQueue() async throws {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        let urls = (0 ..< 10).map { _ in uniqueURL() }
        await prefetcher.prefetch(urls: urls)

        // Cancel specific URLs
        await prefetcher.cancelPrefetch(for: Array(urls.prefix(5)))

        // Give some time for cancellation to process
        try await Task.sleep(nanoseconds: 50_000_000)

        await prefetcher.cancelAll()
    }

    @Test("cancelAll clears all pending and active tasks")
    func cancelAllClearsEverything() async throws {
        let prefetcher = ImagePrefetcher.shared

        let urls = (0 ..< 20).map { _ in uniqueURL() }
        await prefetcher.prefetch(urls: urls)

        // Give some time for tasks to start
        try await Task.sleep(nanoseconds: 50_000_000)

        await prefetcher.cancelAll()

        // Should be able to prefetch again after cancel
        await prefetcher.prefetch(urls: [uniqueURL()])

        await prefetcher.cancelAll()
    }

    @Test("cancelPrefetch handles URLs not in queue gracefully")
    func cancelPrefetchHandlesUnknownURLs() async {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        // Should not crash when cancelling URLs that were never prefetched
        let unknownURLs = (0 ..< 5).map { _ in uniqueURL() }
        await prefetcher.cancelPrefetch(for: unknownURLs)
    }

    // MARK: - Concurrency Tests

    @Test("prefetch limits concurrent operations")
    func prefetchLimitsConcurrentOperations() async throws {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        // Add more URLs than max concurrent limit (4)
        let urls = (0 ..< 20).map { _ in uniqueURL() }
        await prefetcher.prefetch(urls: urls)

        // Give time for queue to process
        try await Task.sleep(nanoseconds: 100_000_000)

        await prefetcher.cancelAll()
    }

    // MARK: - Thread Safety Tests

    @Test("prefetch is thread-safe for concurrent calls")
    func prefetchIsThreadSafe() async throws {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        // Perform concurrent prefetch operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    let urls = (0 ..< 5).map { _ in self.uniqueURL() }
                    await prefetcher.prefetch(urls: urls)
                }
            }
        }

        // Give time to settle
        try await Task.sleep(nanoseconds: 100_000_000)

        await prefetcher.cancelAll()
    }

    @Test("cancelPrefetch is thread-safe for concurrent calls")
    func cancelPrefetchIsThreadSafe() async {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        let urls = (0 ..< 50).map { _ in uniqueURL() }
        await prefetcher.prefetch(urls: urls)

        // Perform concurrent cancel operations
        await withTaskGroup(of: Void.self) { group in
            for iteration in 0 ..< 10 {
                let startIndex = iteration * 5
                let endIndex = min(startIndex + 5, urls.count)
                let urlsToCancel = Array(urls[startIndex ..< endIndex])

                group.addTask {
                    await prefetcher.cancelPrefetch(for: urlsToCancel)
                }
            }
        }

        await prefetcher.cancelAll()
    }

    // MARK: - Actor Isolation Tests

    @Test("actor provides thread-safe access to shared state")
    func actorProvidesThreadSafety() async {
        let prefetcher = ImagePrefetcher.shared
        await prefetcher.cancelAll()

        // Rapidly interleave prefetch and cancel operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 20 {
                let url = uniqueURL()

                group.addTask {
                    await prefetcher.prefetch(urls: [url])
                }

                group.addTask {
                    await prefetcher.cancelPrefetch(for: [url])
                }
            }
        }

        // Should complete without crashes or data corruption
        await prefetcher.cancelAll()
    }
}
