import AppIntents
import Foundation

/// Opens Pulse on the Bookmarks tab to browse saved articles.
struct OpenBookmarksIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Saved Articles"
    static let description = IntentDescription(
        "Opens Pulse on the Bookmarks tab so you can read your saved articles."
    )

    static let openAppWhenRun: Bool = true

    /// Routes to the Bookmarks tab via the shared `DeeplinkManager`.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DeeplinkManager.shared.handle(deeplink: .bookmarks)
        return .result(dialog: "Opening your saved articles")
    }
}
