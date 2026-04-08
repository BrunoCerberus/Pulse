import AppIntents
import Foundation

/// Launches Pulse and runs a news search for the supplied query.
struct SearchPulseIntent: AppIntent {
    static let title: LocalizedStringResource = "Search News in Pulse"
    static let description = IntentDescription(
        "Searches Pulse for news articles matching your query."
    )

    static let openAppWhenRun: Bool = true

    /// The search term to run inside Pulse.
    @Parameter(title: "Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search Pulse for \(\.$query)")
    }

    /// Routes to the Search tab with the provided query via `DeeplinkManager`.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DeeplinkManager.shared.handle(deeplink: .search(query: query))
        return .result(dialog: "Searching for \(query) in Pulse")
    }
}
