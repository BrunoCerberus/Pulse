import AppIntents
import Foundation

/// Opens Pulse on the Feed tab to show the AI-powered Daily Digest.
struct OpenDailyDigestIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Daily Digest"
    static let description = IntentDescription(
        "Opens Pulse on the Feed tab showing your AI-powered Daily Digest."
    )

    static let openAppWhenRun: Bool = true

    /// Routes to the Feed tab via the shared `DeeplinkManager`.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DeeplinkManager.shared.handle(deeplink: .feed)
        return .result(dialog: "Here is your Daily Digest")
    }
}
