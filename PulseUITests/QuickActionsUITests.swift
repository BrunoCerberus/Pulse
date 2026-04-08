import XCTest

/// UI tests for Home Screen Quick Actions.
///
/// XCUITest cannot perform a real Home Screen long-press from inside the app, so these
/// tests rely on the `PULSE_SIMULATE_QUICK_ACTION` launch environment hook in
/// `QuickActionHandler.registerShortcutItems(on:)`. When that variable is set to a
/// `QuickActionType` raw value, the handler synthesizes a matching shortcut item and
/// routes it through the normal `handle(shortcutItem:)` path at scene-connect time.
final class QuickActionsUITests: BaseUITestCase {
    /// Override in individual tests by setting `simulatedQuickAction` before `super.setUp`
    /// is called. `configureLaunchEnvironment()` reads it in.
    private var simulatedQuickAction: String?

    override func configureLaunchEnvironment() {
        super.configureLaunchEnvironment()
        if let simulatedQuickAction {
            app.launchEnvironment["PULSE_SIMULATE_QUICK_ACTION"] = simulatedQuickAction
        }
    }

    // MARK: - Tests

    /// Confirms the app launches cleanly after registering shortcut items. A crash in the
    /// registration path would prevent the app from reaching `runningForeground`.
    func testQuickActionsRegistered() throws {
        try ensureAppRunning()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            safeWaitForExistence(tabBar, timeout: Self.launchTimeout),
            "App should launch and reach the tab bar after registering quick actions"
        )
    }

    /// Simulates the Search quick action by launching with the env var. The handler should
    /// route `.search(query: nil)` to DeeplinkRouter which switches the active tab.
    func testSearchQuickActionOpensSearchTab() throws {
        // Relaunch with the simulate env var so registerShortcutItems routes to .search
        ObjCExceptionCatcher.safeTerminateApp(app)
        _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10)

        simulatedQuickAction = "search"
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["PULSE_SIMULATE_QUICK_ACTION"] = "search"
        app.launchArguments += ["-pulse.hasCompletedOnboarding", "YES"]
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launch()
        _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .runningForeground, timeout: Self.launchTimeout)
        try ensureAppRunning()

        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Search"], timeout: Self.defaultTimeout),
            "Launching with PULSE_SIMULATE_QUICK_ACTION=search should land on the Search tab"
        )
    }

    /// Simulates the Bookmarks quick action by launching with the env var. The handler
    /// should route `.bookmarks` to DeeplinkRouter which switches the active tab.
    func testBookmarksQuickActionOpensBookmarksTab() throws {
        // Relaunch with the simulate env var so registerShortcutItems routes to .bookmarks
        ObjCExceptionCatcher.safeTerminateApp(app)
        _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10)

        simulatedQuickAction = "bookmarks"
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["PULSE_SIMULATE_QUICK_ACTION"] = "bookmarks"
        app.launchArguments += ["-pulse.hasCompletedOnboarding", "YES"]
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launch()
        _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .runningForeground, timeout: Self.launchTimeout)
        try ensureAppRunning()

        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.defaultTimeout),
            "Launching with PULSE_SIMULATE_QUICK_ACTION=bookmarks should land on the Bookmarks tab"
        )
    }
}
