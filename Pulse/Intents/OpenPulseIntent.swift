import AppIntents
import Foundation

/// Launches the Pulse app and navigates to the Home tab.
///
/// Exposed to Siri, Spotlight, and the Shortcuts app so users can open
/// Pulse directly via voice or system UI.
struct OpenPulseIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Pulse"
    static let description = IntentDescription(
        "Opens the Pulse app on the Home tab so you can browse the latest news."
    )

    static let openAppWhenRun: Bool = true

    /// Routes to the Home tab via the shared `DeeplinkManager`.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DeeplinkManager.shared.handle(deeplink: .home)
        return .result(dialog: "Opening Pulse")
    }
}
