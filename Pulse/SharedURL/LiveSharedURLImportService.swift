import Combine
import Foundation

/// Live implementation of `SharedURLImportService` backed by `SharedURLQueue`.
///
/// Drains the App Group queue and publishes each valid `URL` through a
/// `PassthroughSubject`. Malformed URL strings are silently dropped to
/// avoid blocking the queue on a single bad payload.
final class LiveSharedURLImportService: SharedURLImportService, @unchecked Sendable {
    private let pendingURLSubject = PassthroughSubject<URL, Never>()
    private let queue: SharedURLQueue

    init(queue: SharedURLQueue = SharedURLQueue()) {
        self.queue = queue
    }

    var pendingURLPublisher: AnyPublisher<URL, Never> {
        pendingURLSubject.eraseToAnyPublisher()
    }

    var hasPendingItems: Bool {
        !queue.peekAll().isEmpty
    }

    func processPendingItems() {
        let drained = queue.drain()
        guard !drained.isEmpty else { return }
        for item in drained {
            // Defense in depth: re-validate scheme/length on consumption. The
            // queue boundary already rejects bad URLs, but a downgraded App
            // Group write (e.g. forensic injection on a jailbroken device, or
            // a future producer that bypasses validation) shouldn't propagate.
            guard SharedURLQueue.isAcceptable(urlString: item.url),
                  let url = URL(string: item.url)
            else { continue }
            pendingURLSubject.send(url)
        }
    }
}
