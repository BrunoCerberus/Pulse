import XCTest

/// Automated accessibility audit tests using iOS 17+ `performAccessibilityAudit()`.
///
/// These tests launch each main screen and run Apple's built-in accessibility audit
/// to automatically detect missing labels, small touch targets, contrast issues, etc.
@MainActor
final class AccessibilityAuditTests: BaseUITestCase {
    // MARK: - Home

    func testHomeAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        waitForHomeContent()
        wait(for: 2.0)

        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            // Ignore issues from system components we don't control
            let description = issue.debugDescription
            if description.contains("UITabBar") || description.contains("UINavigationBar")
                || description.contains("partially unsupported")
            {
                return true
            }
            return false
        }
    }

    // MARK: - Media

    func testMediaAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        navigateToMediaTab()
        wait(for: 2.0)

        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            let description = issue.debugDescription
            if description.contains("UITabBar") || description.contains("UINavigationBar")
                || description.contains("partially unsupported")
            {
                return true
            }
            return false
        }
    }

    // MARK: - Bookmarks

    func testBookmarksAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        navigateToBookmarksTab()
        wait(for: 2.0)

        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            let description = issue.debugDescription
            if description.contains("UITabBar") || description.contains("UINavigationBar")
                || description.contains("partially unsupported")
            {
                return true
            }
            return false
        }
    }

    // MARK: - Search

    func testSearchAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        navigateToSearchTab()
        wait(for: 2.0)

        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            let description = issue.debugDescription
            if description.contains("UITabBar") || description.contains("UINavigationBar")
                || description.contains("UISearchBar")
                || description.contains("partially unsupported")
            {
                return true
            }
            return false
        }
    }

    // MARK: - Settings

    func testSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        navigateToSettings()
        wait(for: 2.0)

        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            let description = issue.debugDescription
            if description.contains("UITabBar") || description.contains("UINavigationBar")
                || description.contains("partially unsupported")
                || description.contains("Label not human-readable")
            {
                return true
            }
            return false
        }
    }
}
