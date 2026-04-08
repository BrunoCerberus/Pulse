import Combine
import Foundation

/// Mock `SharedURLImportService` used in unit and UI tests.
///
/// Tests can preload `pendingURLs` to simulate a queued state, then call
/// `processPendingItems()` to flush them through `pendingURLPublisher`,
/// or call `simulateIncomingURL(_:)` to push a single URL without touching
/// the internal queue.
final class MockSharedURLImportService: SharedURLImportService, @unchecked Sendable {
    private let pendingURLSubject = PassthroughSubject<URL, Never>()

    /// URLs that will be emitted on the next `processPendingItems()` call.
    var pendingURLs: [URL] = []

    /// Number of times `processPendingItems()` has been invoked.
    private(set) var processCallCount = 0

    var pendingURLPublisher: AnyPublisher<URL, Never> {
        pendingURLSubject.eraseToAnyPublisher()
    }

    var hasPendingItems: Bool {
        !pendingURLs.isEmpty
    }

    func processPendingItems() {
        processCallCount += 1
        let snapshot = pendingURLs
        pendingURLs.removeAll()
        for url in snapshot {
            pendingURLSubject.send(url)
        }
    }

    /// Pushes a single URL through the publisher without touching `pendingURLs`.
    func simulateIncomingURL(_ url: URL) {
        pendingURLSubject.send(url)
    }

    /// Resets recorded state for the next test.
    func reset() {
        pendingURLs.removeAll()
        processCallCount = 0
    }
}
