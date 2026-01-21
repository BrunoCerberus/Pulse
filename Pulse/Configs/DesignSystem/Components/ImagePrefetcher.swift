import Foundation
import UIKit

/// A service that prefetches images in the background to improve scroll performance.
/// Integrates with the existing `ImageCache` for deduplication and storage.
final class ImagePrefetcher: @unchecked Sendable {
    static let shared = ImagePrefetcher()

    /// Maximum number of concurrent prefetch operations
    private let maxConcurrentPrefetches = 4

    /// Currently active prefetch tasks
    private var activeTasks: [URL: Task<Void, Never>] = [:]
    private let tasksLock = NSLock()

    /// Pending URLs waiting to be prefetched
    private var pendingURLs: [URL] = []
    private let pendingLock = NSLock()

    private init() {}

    // MARK: - Public API

    /// Prefetches images for the given URLs in the background.
    /// Already-cached images are skipped. Prefetch runs at low priority.
    /// - Parameter urls: The image URLs to prefetch
    func prefetch(urls: [URL]) {
        let urlsToFetch = urls.filter { url in
            // Skip if already cached
            if ImageCache.shared.image(for: url) != nil {
                return false
            }
            // Skip if already being fetched
            return tasksLock.withLock { activeTasks[url] == nil }
        }

        guard !urlsToFetch.isEmpty else { return }

        // Add to pending queue
        pendingLock.withLock {
            for url in urlsToFetch where !pendingURLs.contains(url) {
                pendingURLs.append(url)
            }
        }

        // Process pending queue
        processQueue()
    }

    /// Cancels prefetch operations for the given URLs.
    /// Called when items scroll out of view to free up resources.
    /// - Parameter urls: The image URLs to cancel prefetching for
    func cancelPrefetch(for urls: [URL]) {
        for url in urls {
            // Remove from pending queue
            pendingLock.withLock {
                pendingURLs.removeAll { $0 == url }
            }

            // Cancel active task if running
            let task = tasksLock.withLock { activeTasks.removeValue(forKey: url) }
            task?.cancel()
        }
    }

    /// Cancels all pending and active prefetch operations.
    func cancelAll() {
        // Clear pending queue
        pendingLock.withLock {
            pendingURLs.removeAll()
        }

        // Cancel all active tasks
        let tasks = tasksLock.withLock {
            let allTasks = Array(activeTasks.values)
            activeTasks.removeAll()
            return allTasks
        }

        for task in tasks {
            task.cancel()
        }
    }

    // MARK: - Private

    private func processQueue() {
        // Get current active count
        let activeCount = tasksLock.withLock { activeTasks.count }
        let slotsAvailable = maxConcurrentPrefetches - activeCount

        guard slotsAvailable > 0 else { return }

        // Get URLs to process
        let urlsToProcess = pendingLock.withLock {
            let count = min(slotsAvailable, pendingURLs.count)
            let urls = Array(pendingURLs.prefix(count))
            pendingURLs.removeFirst(count)
            return urls
        }

        for url in urlsToProcess {
            let task = Task(priority: .low) { [weak self] in
                guard let self else { return }
                await self.fetchImage(at: url)
            }

            tasksLock.withLock {
                activeTasks[url] = task
            }
        }
    }

    private func fetchImage(at url: URL) async {
        defer {
            // Remove from active and process more
            tasksLock.withLock {
                activeTasks.removeValue(forKey: url)
            }
            processQueue()
        }

        // Check for cancellation before fetching
        guard !Task.isCancelled else { return }

        do {
            // Use existing ImageCache infrastructure
            _ = try await ImageCache.shared.loadImage(from: url)
        } catch {
            // Silently fail - prefetch is best-effort
            // Image will be loaded normally on display if prefetch fails
        }
    }
}
