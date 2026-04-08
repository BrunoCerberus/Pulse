import Combine
import Foundation

/// Service responsible for consuming URLs that the Share Extension has
/// queued in the App Group container.
///
/// The Share Extension cannot run the on-device LLM (model size exceeds
/// the extension memory budget), so it persists `SharedURLItem` records
/// to disk via `SharedURLQueue` and then opens the main app via the
/// `pulse://shared` URL scheme. The main app implements this protocol to
/// drain that queue on launch / foreground and publish each pending URL
/// for downstream features (e.g. ArticleDetail summarization) to consume.
protocol SharedURLImportService {
    /// Publisher emitting the next pending shared URL each time
    /// `processPendingItems()` finds an item in the App Group queue.
    var pendingURLPublisher: AnyPublisher<URL, Never> { get }

    /// Drains the App Group queue and publishes any pending URLs through
    /// `pendingURLPublisher`. Safe to call from scene activation or app
    /// foregrounding hooks.
    func processPendingItems()

    /// Returns `true` if the queue currently has at least one pending item
    /// without consuming it.
    var hasPendingItems: Bool { get }
}
