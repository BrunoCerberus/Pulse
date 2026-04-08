import AppIntents
import Foundation

/// Opens the Pulse Settings screen.
struct OpenPulseSettingsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Pulse Settings"
    static let description = IntentDescription(
        "Opens the Pulse Settings screen to manage topics, notifications, and preferences."
    )

    static let openAppWhenRun: Bool = true

    /// Routes to the Settings screen via the shared `DeeplinkManager`.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DeeplinkManager.shared.handle(deeplink: .settings)
        return .result(dialog: "Opening Pulse Settings")
    }
}
