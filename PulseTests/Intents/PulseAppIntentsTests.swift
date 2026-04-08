import AppIntents
import Foundation
@testable import Pulse
import Testing

@Suite("Pulse App Intents Tests", .serialized)
@MainActor
struct PulseAppIntentsTests {
    let deeplinkManager: DeeplinkManager

    init() {
        deeplinkManager = DeeplinkManager.shared
        deeplinkManager.clearDeeplink()
    }

    // MARK: - OpenPulseIntent

    @Test("OpenPulseIntent routes to home deeplink")
    func openPulseIntentRoutesToHome() async throws {
        let intent = OpenPulseIntent()

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .home)
    }

    // MARK: - OpenDailyDigestIntent

    @Test("OpenDailyDigestIntent routes to feed deeplink")
    func openDailyDigestIntentRoutesToFeed() async throws {
        let intent = OpenDailyDigestIntent()

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .feed)
    }

    // MARK: - OpenBookmarksIntent

    @Test("OpenBookmarksIntent routes to bookmarks deeplink")
    func openBookmarksIntentRoutesToBookmarks() async throws {
        let intent = OpenBookmarksIntent()

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .bookmarks)
    }

    // MARK: - OpenPulseSettingsIntent

    @Test("OpenPulseSettingsIntent routes to settings deeplink")
    func openPulseSettingsIntentRoutesToSettings() async throws {
        let intent = OpenPulseSettingsIntent()

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .settings)
    }

    // MARK: - SearchPulseIntent

    @Test("SearchPulseIntent routes to search with query")
    func searchPulseIntentRoutesToSearchWithQuery() async throws {
        let intent = SearchPulseIntent()
        intent.query = "swift"

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .search(query: "swift"))
    }

    @Test("SearchPulseIntent preserves multi-word query verbatim")
    func searchPulseIntentPreservesMultiWordQuery() async throws {
        let intent = SearchPulseIntent()
        intent.query = "climate change"

        _ = try await intent.perform()

        #expect(deeplinkManager.currentDeeplink == .search(query: "climate change"))
    }

    // MARK: - Intent Metadata

    @Test("All intents open the app when run")
    func allIntentsOpenAppWhenRun() {
        #expect(OpenPulseIntent.openAppWhenRun == true)
        #expect(OpenDailyDigestIntent.openAppWhenRun == true)
        #expect(OpenBookmarksIntent.openAppWhenRun == true)
        #expect(SearchPulseIntent.openAppWhenRun == true)
        #expect(OpenPulseSettingsIntent.openAppWhenRun == true)
    }

    // MARK: - PulseAppShortcuts

    @Test("PulseAppShortcuts exposes all expected intents")
    func pulseAppShortcutsContainsAllIntents() {
        let shortcuts = PulseAppShortcuts.appShortcuts

        #expect(shortcuts.count >= 5)
    }
}
