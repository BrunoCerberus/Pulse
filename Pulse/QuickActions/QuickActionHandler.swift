import Foundation
import UIKit

/// Coordinates Home Screen Quick Actions: registration on launch and routing to deeplinks.
@MainActor
final class QuickActionHandler {
    static let shared = QuickActionHandler()

    /// Pending quick action captured at launch (before the scene is ready) that will be routed
    /// once the coordinator becomes available. Set by `handle(shortcutItem:)` and consumed by
    /// `flushPendingIfNeeded()`.
    private(set) var pendingType: QuickActionType?

    /// Injection seam for tests — defaults to the real DeeplinkManager.
    var deeplinkHandler: (Deeplink) -> Void = { DeeplinkManager.shared.handle(deeplink: $0) }

    private init() {}

    /// Registers all static quick actions on the application (idempotent).
    ///
    /// When the `PULSE_SIMULATE_QUICK_ACTION` environment variable is set (UI tests only),
    /// this method also synthesizes a shortcut item matching that raw value and routes it
    /// through `handle(shortcutItem:)` so UI tests can verify the quick-action flow without
    /// a real Home Screen long-press.
    func registerShortcutItems(on application: UIApplication = .shared) {
        application.shortcutItems = QuickActionType.allCases.map { $0.shortcutItem() }

        if let simulated = ProcessInfo.processInfo.environment["PULSE_SIMULATE_QUICK_ACTION"],
           let type = QuickActionType(rawValue: simulated)
        {
            handle(shortcutItem: type.shortcutItem())
        }
    }

    /// Handles a shortcut item tap. If the coordinator isn't ready yet, stores the pending
    /// action; the DeeplinkManager handles queueing if the coordinator is merely unavailable
    /// in the DeeplinkRouter yet.
    /// - Returns: true if the shortcut was recognized.
    @discardableResult
    func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let type = QuickActionType(shortcutItem: shortcutItem) else {
            return false
        }
        let deeplink = deeplink(for: type)
        deeplinkHandler(deeplink)
        pendingType = type // kept for observability/tests
        return true
    }

    /// Clears the pending action (useful for tests).
    func clearPending() {
        pendingType = nil
    }

    private func deeplink(for type: QuickActionType) -> Deeplink {
        switch type {
        case .search: .search(query: nil)
        case .dailyDigest: .feed
        case .bookmarks: .bookmarks
        case .breakingNews: .home
        }
    }
}
