import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
@MainActor
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Timeout for app launch verification - requires more time than element checks
    static let launchTimeout: TimeInterval = 8

    /// Default timeout for element existence checks
    /// 4s is sufficient with animations disabled - elements appear quickly
    static let defaultTimeout: TimeInterval = 4

    /// Short timeout for quick checks (e.g., verifying element visibility)
    /// 1.5s is enough for immediate UI responses
    static let shortTimeout: TimeInterval = 1.5

    // MARK: - Instance-level Setup (runs before each test)

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()

        // Speed optimizations
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"

        // Launch arguments to speed up tests
        app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
        app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]

        app.launch()

        // Launch verification - uses longer timeout as app startup takes time
        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)
        _ = app.tabBars.firstMatch.waitForExistence(timeout: Self.launchTimeout)

        // Ensure app is in a clean state
        resetToHomeTab()
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        if app?.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Reset to Home tab to start each test from a known state
    func resetToHomeTab() {
        let tabBar = app.tabBars.firstMatch

        // Quick check - if tab bar not visible, try recovery
        if !tabBar.waitForExistence(timeout: Self.shortTimeout) {
            let backButton = app.buttons["backButton"]
            if backButton.exists { backButton.tap() }
            guard tabBar.waitForExistence(timeout: 1) else { return }
        }

        // Select Home tab - use combined predicate for efficiency
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        } else if !homeTab.exists {
            // Fallback: tap first tab (Home is always first)
            tabBar.buttons.element(boundBy: 0).tap()
        }

        // Pop all navigation stack levels (handles deep navigation states)
        for _ in 0..<3 {
            let backButton = app.buttons["backButton"]
            guard backButton.exists, backButton.isHittable else { break }
            backButton.tap()
            wait(for: 0.2) // Allow navigation animation to settle
        }
    }

    /// Navigate to a specific tab
    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        if tab.waitForExistence(timeout: Self.shortTimeout), !tab.isSelected {
            tab.tap()
        }
    }

    /// Navigate to Search tab (handles role: .search accessibility)
    func navigateToSearchTab() {
        // Try multiple strategies to find the Search tab button
        // Strategy 1: Try by label "Search"
        let searchTab = app.tabBars.buttons["Search"]
        if searchTab.waitForExistence(timeout: Self.shortTimeout), !searchTab.isSelected {
            searchTab.tap()
            _ = app.navigationBars["Search"].waitForExistence(timeout: Self.shortTimeout)
            return
        }

        // Strategy 2: Try by matching predicate (label or identifier contains "search")
        let searchTabPredicate = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")
        ).firstMatch
        if searchTabPredicate.exists, !searchTabPredicate.isSelected {
            searchTabPredicate.tap()
            _ = app.navigationBars["Search"].waitForExistence(timeout: Self.shortTimeout)
            return
        }

        // Strategy 3: Try by position (Search is the 4th tab: Home, For You, Bookmarks, Search)
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let buttons = tabBar.buttons
            if buttons.count >= 4 {
                let fourthTab = buttons.element(boundBy: 3)
                if fourthTab.exists, !fourthTab.isSelected {
                    fourthTab.tap()
                    _ = app.navigationBars["Search"].waitForExistence(timeout: Self.shortTimeout)
                }
            }
        }
    }

    /// Navigate to For You tab and verify navigation bar appears
    func navigateToForYouTab() {
        let forYouTab = app.tabBars.buttons["For You"]
        if forYouTab.exists, !forYouTab.isSelected {
            forYouTab.tap()
        }
        _ = app.navigationBars["For You"].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Navigate to Digest tab and verify navigation bar appears
    func navigateToDigestTab() {
        let digestTab = app.tabBars.buttons["Digest"]
        if digestTab.exists, !digestTab.isSelected {
            digestTab.tap()
        }
        _ = app.navigationBars["Digest"].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Navigate to Bookmarks tab and verify navigation bar appears
    func navigateToBookmarksTab() {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        if bookmarksTab.exists, !bookmarksTab.isSelected {
            bookmarksTab.tap()
        }
        _ = app.navigationBars["Bookmarks"].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        navigateToTab("Home")
        let gearButton = app.navigationBars.buttons["gearshape"]
        if gearButton.waitForExistence(timeout: Self.shortTimeout) {
            gearButton.tap()
            _ = app.navigationBars["Settings"].waitForExistence(timeout: Self.shortTimeout)
        }
    }

    // MARK: - Wait Helpers

    /// Smart wait that replaces Thread.sleep - waits for UI to settle
    /// Uses RunLoop to allow UI updates while waiting, more efficient than Thread.sleep
    @discardableResult
    func wait(for duration: TimeInterval) -> Bool {
        // Use expectation-based waiting which is more efficient than Thread.sleep
        // and allows the UI to continue processing events
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(value: false),
            object: nil
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: duration)
        return true
    }

    /// Wait for any of the provided elements to exist - efficient predicate-based waiting
    func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate { _, _ in elements.contains { $0.exists } }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Wait for any element matching query to exist
    func waitForAnyMatch(_ query: XCUIElementQuery, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate { _, _ in query.count > 0 }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Wait for content to load (articles, error, or empty state)
    func waitForHomeContent(timeout: TimeInterval = 20) -> Bool {
        let contentIndicators = [
            app.staticTexts["Breaking News"],
            app.staticTexts["Top Headlines"],
            app.staticTexts["Unable to Load News"],
            app.staticTexts["No News Available"],
            app.scrollViews.firstMatch, // Fallback: wait for scroll view to appear
        ]
        return waitForAny(contentIndicators, timeout: timeout)
    }

    /// Wait for article detail view
    func waitForArticleDetail(timeout: TimeInterval = 5) -> Bool {
        let detailScrollView = app.scrollViews["articleDetailScrollView"]
        if detailScrollView.waitForExistence(timeout: timeout) {
            return true
        }
        return app.buttons["backButton"].waitForExistence(timeout: 1)
    }

    /// Navigate back from current view
    func navigateBack() {
        let backButton = app.buttons["backButton"]
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }
    }

    // MARK: - Element Helpers

    /// Find article cards
    func articleCards() -> XCUIElementQuery {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour' OR label CONTAINS[c] 'minute'")
        )
    }

    /// Check if element is visible in the viewport
    func isElementVisible(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        guard !frame.isEmpty else { return false }
        return app.windows.element(boundBy: 0).frame.intersects(frame)
    }

    /// Scroll to find an element
    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement? = nil, maxSwipes: Int = 5) -> Bool {
        if element.exists, element.isHittable {
            return true
        }

        let container = scrollView ?? app.scrollViews.firstMatch
        guard container.exists else { return false }

        for _ in 0..<maxSwipes {
            container.swipeUp()
            // Use element check instead of fixed delay
            if element.waitForExistence(timeout: 0.1), element.isHittable {
                return true
            }
        }
        return false
    }
}
