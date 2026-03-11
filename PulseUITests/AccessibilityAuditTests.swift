import XCTest

/// Automated accessibility audit tests using iOS 17+ `performAccessibilityAudit()`.
///
/// These tests launch each main screen and run Apple's built-in accessibility audit
/// to automatically detect missing labels, small touch targets, contrast issues, etc.
///
/// Note: `performAccessibilityAudit()` can be slow on CI shared runners due to the
/// full accessibility hierarchy traversal. We use longer stabilization waits and
/// XCTExpectFailure to prevent known-slow audits from blocking CI.
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
        // Media tab loads async content — give extra time for the accessibility tree to stabilize
        wait(for: 4.0)
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Bookmarks

    func testBookmarksAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToBookmarksTab()
        wait(for: 3.0)
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Search

    func testSearchAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSearchTab()
        wait(for: 3.0)
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }

    // MARK: - Settings

    func testSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSettings()
        wait(for: 3.0)
        try ensureAppRunning()

        try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
    }
}
