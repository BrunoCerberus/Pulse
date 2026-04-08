import AppIntents
import Foundation

/// Declares the set of App Shortcuts surfaced by Pulse to Siri, Spotlight,
/// and the Shortcuts app.
///
/// Each shortcut maps an `AppIntent` to one or more natural-language phrases
/// that users can invoke. Phrases must include `\(.applicationName)` so Siri
/// can disambiguate between apps.
struct PulseAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenPulseIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Launch \(.applicationName)",
                "Show me the news in \(.applicationName)",
            ],
            shortTitle: "Open Pulse",
            systemImageName: "newspaper"
        )

        AppShortcut(
            intent: OpenDailyDigestIntent(),
            phrases: [
                "Show my Daily Digest in \(.applicationName)",
                "Open my Daily Digest in \(.applicationName)",
                "What's in my \(.applicationName) digest",
            ],
            shortTitle: "Daily Digest",
            systemImageName: "text.document"
        )

        AppShortcut(
            intent: OpenBookmarksIntent(),
            phrases: [
                "Open my saved articles in \(.applicationName)",
                "Show my bookmarks in \(.applicationName)",
                "Show saved articles in \(.applicationName)",
            ],
            shortTitle: "Saved Articles",
            systemImageName: "bookmark"
        )

        // Note: App Shortcut phrases only support `\(.applicationName)` and
        // interpolations of `AppEntity` / `AppEnum` parameters. A plain
        // `String` parameter (our `query`) cannot appear inline in the phrase,
        // so we use generic invocation phrases and Siri will prompt the user
        // for the query when the shortcut is invoked.
        AppShortcut(
            intent: SearchPulseIntent(),
            phrases: [
                "Search news in \(.applicationName)",
                "Search \(.applicationName)",
                "Find articles in \(.applicationName)",
            ],
            shortTitle: "Search News",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: OpenPulseSettingsIntent(),
            phrases: [
                "Open \(.applicationName) settings",
                "Show \(.applicationName) settings",
                "Change \(.applicationName) preferences",
            ],
            shortTitle: "Pulse Settings",
            systemImageName: "gearshape"
        )
    }
}
