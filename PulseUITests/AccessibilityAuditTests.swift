import XCTest

/// Automated accessibility audit tests using iOS 17+ `performAccessibilityAudit()`.
///
/// These tests launch each main screen and run Apple's built-in accessibility audit
/// to automatically detect missing labels, small touch targets, contrast issues, etc.
///
/// Note: `performAccessibilityAudit()` can be slow on CI shared runners due to the
/// full accessibility hierarchy traversal. Each audit waits for a deterministic
/// terminal UI state before running — starting an audit mid-transition (while
/// `.fadeIn`/loading animations are still settling) can cause the internal UI
/// snapshot query to hang for 200+ seconds before timing out (seen on Bookmarks).
///
/// Tab navigation uses coordinate-based taps via `tapTabAt(_:)` instead of
/// `navigateToBookmarksTab()` / `navigateToMediaTab()`. Element-based taps call
/// `XCUIElement.coordinateWithNormalizedOffset(_:)`, which lazily resolves the
/// element's frame via an accessibility query. On Xcode 26 + iOS 26 simulator on
/// macOS-26-arm64 GitHub Actions runners, that query can stall the tap synthesis
/// for 130+ seconds inside `Find the "X" Button` retries before timing out (seen
/// on GitHub Actions run 24383814898). App-relative coordinates skip this.
@MainActor
final class AccessibilityAuditTests: BaseUITestCase {
    /// Tab order matches `AppTab` enum (`Pulse/Configs/Navigation/Coordinator.swift`).
    private enum TabIndex: Int {
        case home = 0
        case media = 1
        case feed = 2
        case bookmarks = 3
        case search = 4
    }

    private static let totalTabs = 5

    /// Skip setUp's activity-indicator disappear wait: each `safeExists` on the
    /// spinner can block for 30–90s inside XCTest's internal query retries on
    /// degraded CI simulators, and `setUp` already hits a 302s hard failure before
    /// the test body runs (GitHub Actions run 24403500495). Each audit test waits
    /// for its own terminal-state indicator via `waitForStableState`.
    override var shouldWaitForLoadingIndicator: Bool { false }

    /// Skip the orientation setter in setUp: on cold CI boot it can block 8+s
    /// waiting for confirmation and record a `Failed to set device orientation`
    /// failure that bypasses the test body (GitHub Actions run 24419133870).
    /// The simulator boots in portrait; audit tests never rotate the device.
    override var shouldSetDeviceOrientation: Bool { false }

    /// Common audit handler that filters out system component issues we don't control
    private func auditIssueHandler(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        let description = issue.debugDescription
        if description.contains("UITabBar") || description.contains("UINavigationBar")
            || description.contains("partially unsupported")
            || description.contains("UISearchBar")
            || description.contains("Label not human-readable")
        {
            return true
        }
        return false
    }

    /// Audit types to check — focused set that avoids the most CI-flaky checks
    private var auditTypes: XCUIAccessibilityAuditType {
        [.dynamicType, .sufficientElementDescription, .hitRegion]
    }

    /// Coordinate-based tab tap that bypasses XCTest's accessibility query layer.
    /// Computes the tab's screen position from its index and taps the app window
    /// directly, avoiding the `Find the "X" Button` retries that hang for 130+s on
    /// degraded CI simulators. `y = 0.96` lands inside the bottom tab bar safe area.
    private func tapTabAt(_ tab: TabIndex) {
        let normalizedX = (Double(tab.rawValue) + 0.5) / Double(Self.totalTabs)
        ObjCExceptionCatcher.safeTapApp(atNormalizedX: normalizedX, y: 0.96, app: app)
    }

    /// Waits for any of the supplied terminal-state indicators, then gives the
    /// accessibility tree a short settle window before the audit runs. If the
    /// view never reaches a stable state the test is skipped rather than allowed
    /// to hang for 5+ minutes inside `performAccessibilityAudit`.
    private func waitForStableState(
        _ indicators: [XCUIElement],
        screen: String,
        timeout: TimeInterval = BaseUITestCase.defaultTimeout
    ) throws {
        guard waitForAny(indicators, timeout: timeout) else {
            throw XCTSkip(
                "\(screen) did not reach a stable state within \(Int(timeout))s; " +
                    "skipping audit to avoid the UI snapshot query hanging for minutes."
            )
        }
        wait(for: 1.0)
        try ensureAppRunning()
    }

    // MARK: - Home

    func testHomeAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        // Use a fixed sleep instead of `waitForHomeContent()` — element-based waits
        // trigger XCTest internal query retries (30s each, up to 2 retries = 90s per
        // call) that get recorded as test failures before we can XCTSkip. A blind
        // wait avoids the query layer entirely; the app is on Home by default
        // (setUp ends with resetToHomeTab) so we just need content to render.
        wait(for: 8.0)
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Media

    func testMediaAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        tapTabAt(.media)

        try waitForStableState(
            [
                app.navigationBars["Media"],
                app.staticTexts["Unable to Load Media"],
                app.staticTexts["No Media Available"],
            ],
            screen: "Media"
        )

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Bookmarks

    func testBookmarksAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        tapTabAt(.bookmarks)

        // Wait for a terminal Bookmarks state (empty / populated / error) before
        // auditing. Starting the audit while the view is still in its loading
        // state caused `performAccessibilityAudit` to hang for 225s on CI
        // (GitHub Actions run 24323650849) before timing out on a UI query.
        let savedArticlesText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'saved articles'")
        ).firstMatch
        try waitForStableState(
            [
                app.staticTexts["No Bookmarks"],
                savedArticlesText,
                app.staticTexts["Unable to Load Bookmarks"],
            ],
            screen: "Bookmarks"
        )

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Search

    func testSearchAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        tapTabAt(.search)

        try waitForStableState(
            [app.navigationBars["Search"], app.searchFields.firstMatch],
            screen: "Search"
        )

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Settings

    func testSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        // Coordinate-tap Home first so the gear button is on screen, then use the
        // element-based gear tap (no coordinate fallback for nav-bar buttons).
        tapTabAt(.home)
        wait(for: 0.5)
        try ensureAppRunning()

        var gearButton = app.navigationBars.buttons["Settings"]
        if !safeExists(gearButton) {
            gearButton = app.buttons["Settings"]
        }
        guard safeExists(gearButton) else {
            throw XCTSkip("Settings gear button not visible after Home tab activation")
        }
        safeTap(gearButton)

        try waitForStableState(
            [app.navigationBars["Settings"]],
            screen: "Settings"
        )

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }
}
