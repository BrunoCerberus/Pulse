import Foundation
import UIKit

// MARK: - Prefetch Error

/// Errors specific to image prefetching operations.
/// Separate from CancellationError for better debugging and logging.
private enum PrefetchError: Error, CustomStringConvertible {
    /// The prefetch operation exceeded the configured timeout.
    /// This typically indicates a slow or stalled network request.
    case timeout

    var description: String {
        switch self {
        case .timeout:
            return "Prefetch operation timed out"
        }
    }
}

// MARK: - Image Prefetcher

/// A service that prefetches images in the background to improve scroll performance.
/// Integrates with the existing `ImageCache` for deduplication and storage.
///
/// Thread Safety: This actor provides built-in synchronization for all mutable state.
/// All public methods can be safely called from any context.
actor ImagePrefetcher {
    /// Shared singleton instance for app-wide image prefetching.
    static let shared = ImagePrefetcher()

    // MARK: - Configuration

    /// Maximum number of concurrent prefetch operations.
    /// Set to 4 to balance between prefetch speed and avoiding network/memory pressure.
    /// Higher values may cause memory spikes on image-heavy feeds.
    private let maxConcurrentPrefetches = 4

    /// Timeout for prefetch operations in nanoseconds.
    /// Set to 30 seconds to prevent leaked tasks from slow/stalled network requests.
    /// This ensures tasks are cleaned up even if the network layer hangs.
    private let prefetchTimeout: UInt64 = 30_000_000_000

    // MARK: - State

    /// Currently active prefetch tasks keyed by URL
    private var activeTasks: [URL: Task<Void, Never>] = [:]

    /// Pending URLs waiting to be prefetched, stored as Array to maintain FIFO order
    /// and enable efficient batch removal from the front
    private var pendingURLs: [URL] = []

    /// Set for O(1) lookup to check if URL is already pending
    private var pendingURLsSet = Set<URL>()

    private let logCategory = "ImagePrefetcher"

    private init() {}

    // MARK: - Public API

    /// Prefetches images for the given URLs in the background.
    /// Already-cached images are skipped. Prefetch runs at low priority.
    ///
    /// - Parameter urls: The image URLs to prefetch
    func prefetch(urls: [URL]) async {
        // Filter out cached, pending, and active URLs in a single pass within actor isolation.
        // This eliminates race conditions between cache check and queue state check.
        let newURLs = urls.filter { url in
            guard ImageCache.shared.image(for: url) == nil else { return false }
            return !pendingURLsSet.contains(url) && activeTasks[url] == nil
        }
        guard !newURLs.isEmpty else { return }

        // Add to pending queue maintaining FIFO order
        for url in newURLs {
            pendingURLs.append(url)
            pendingURLsSet.insert(url)
        }

        // Process pending queue
        processQueue()
    }

    /// Cancels prefetch operations for the given URLs.
    /// Called when items scroll out of view to free up resources.
    ///
    /// - Parameter urls: The image URLs to cancel prefetching for
    func cancelPrefetch(for urls: [URL]) {
        let urlSet = Set(urls)

        // Remove from pending queue
        pendingURLs.removeAll { urlSet.contains($0) }
        pendingURLsSet.subtract(urlSet)

        // Cancel active tasks
        for url in urls {
            if let task = activeTasks.removeValue(forKey: url) {
                task.cancel()
            }
        }
    }

    /// Cancels all pending and active prefetch operations.
    func cancelAll() {
        // Clear pending queue
        pendingURLs.removeAll()
        pendingURLsSet.removeAll()

        // Cancel all active tasks
        let tasks = Array(activeTasks.values)
        activeTasks.removeAll()

        for task in tasks {
            task.cancel()
        }
    }

    // MARK: - Private

    private func processQueue() {
        let slotsAvailable = maxConcurrentPrefetches - activeTasks.count

        guard slotsAvailable > 0, !pendingURLs.isEmpty else { return }

        // Take URLs from front of queue (FIFO) - O(n) but n is small (≤4)
        let count = min(slotsAvailable, pendingURLs.count)
        let urlsToProcess = Array(pendingURLs.prefix(count))
        pendingURLs.removeFirst(count)

        // Remove from lookup set
        for url in urlsToProcess {
            pendingURLsSet.remove(url)
        }

        for url in urlsToProcess {
            // Strong self capture is safe here - ImagePrefetcher is a singleton
            // that lives for the app's lifetime
            let task = Task(priority: .low) {
                await self.fetchImage(at: url)
            }
            activeTasks[url] = task
        }
    }

    private func fetchImage(at url: URL) async {
        defer {
            // Remove from active and process more
            activeTasks.removeValue(forKey: url)
            processQueue()
        }

        // Check for cancellation before fetching
        guard !Task.isCancelled else { return }

        do {
            // Race between image fetch and timeout to prevent leaked tasks
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = try await ImageCache.shared.loadImage(from: url)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: self.prefetchTimeout)
                    throw PrefetchError.timeout
                }
                // Wait for first to complete, cancel the other
                _ = try await group.next()
                group.cancelAll()
            }
        } catch is CancellationError {
            // Task was explicitly cancelled (e.g., user scrolled past item)
            Logger.shared.debug("Prefetch cancelled: \(url.absoluteString)", category: logCategory)
        } catch PrefetchError.timeout {
            // Prefetch exceeded timeout - network may be slow/stalled
            Logger.shared.debug("Prefetch timed out after 30s: \(url.absoluteString)", category: logCategory)
        } catch {
            // Log unexpected errors for debugging while still failing silently
            // Image will be loaded normally on display if prefetch fails
            let errMsg = error.localizedDescription
            Logger.shared.warning("Prefetch failed for \(url.absoluteString): \(errMsg)", category: logCategory)
        }
    }
}
