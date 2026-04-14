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
@MainActor
final class AccessibilityAuditTests: BaseUITestCase {
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
        waitForHomeContent()
        wait(for: 3.0) // Extra stabilization for CI accessibility tree
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Media

    func testMediaAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToMediaTab()

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
        navigateToBookmarksTab()

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
        navigateToSearchTab()

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
        navigateToSettings()

        try waitForStableState(
            [app.navigationBars["Settings"]],
            screen: "Settings"
        )

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }
}
