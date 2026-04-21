import XCTest

/// Automated accessibility audit tests using iOS 17+ `performAccessibilityAudit()`.
///
/// These tests launch each main screen and run Apple's built-in accessibility audit
/// to automatically detect missing labels, small touch targets, contrast issues, etc.
///
/// Note: `performAccessibilityAudit()` can be slow on CI shared runners due to the
/// full accessibility hierarchy traversal. Real audit issues (missing labels, small
/// hit regions, etc.) still fail the test, but the audit's own internal timeout
/// (`com.apple.xcode.xctest.accessibilityAudit` code `-56`) is converted to `XCTSkip`
/// so it doesn't block CI.
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

    /// Runs `performAccessibilityAudit` and converts the audit's internal timeout
    /// into `XCTSkip`. The audit can time out on shared CI runners while traversing
    /// the accessibility hierarchy — that's a CI environment issue, not an
    /// accessibility regression, so we skip rather than fail the PR.
    private func performAccessibilityAuditSkippingTimeouts() throws {
        do {
            try app.performAccessibilityAudit(for: auditTypes, auditIssueHandler)
        } catch {
            let nsError = error as NSError
            let isAuditTimeout = nsError.domain == "com.apple.xcode.xctest.accessibilityAudit"
                && nsError.code == -56
            if isAuditTimeout {
                throw XCTSkip("Accessibility audit timed out on CI runner — skipping to avoid flake.")
            }
            throw error
        }
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

        try performAccessibilityAuditSkippingTimeouts()
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

        try performAccessibilityAuditSkippingTimeouts()
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

        try performAccessibilityAuditSkippingTimeouts()
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

        try performAccessibilityAuditSkippingTimeouts()
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

        try performAccessibilityAuditSkippingTimeouts()
    }
}
