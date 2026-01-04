import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Default timeout for element existence checks
    /// 8s provides good balance between speed and reliability
    /// Tests run with animations disabled, so elements appear quickly
    static let defaultTimeout: TimeInterval = 8

    /// Short timeout for quick checks (e.g., verifying element visibility)
    static let shortTimeout: TimeInterval = 3

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

        _ = app.wait(for: .runningForeground, timeout: 15.0)
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15.0)

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
        if !tabBar.waitForExistence(timeout: Self.shortTimeout) {
            // Quick recovery: try back button
            let backButton = app.buttons["backButton"]
            if backButton.exists { backButton.tap() }
            guard tabBar.waitForExistence(timeout: 2) else {
                XCTFail("Tab bar not found after recovery attempt")
                return
            }
        }

        // Select Home tab with smart fallback
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        } else if !homeTab.exists {
            // Try to find any tab with "Home" identifier/label
            let homeTabFallback = tabBar.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'home' OR identifier CONTAINS[c] 'home'")
            ).firstMatch
            if homeTabFallback.exists {
                homeTabFallback.tap()
            } else {
                // Last resort: tap first tab (assumed to be Home)
                tabBar.buttons.element(boundBy: 0).tap()
            }
        }

        // Verify Home loaded successfully
        let homeNavBar = app.navigationBars["News"]
        if !homeNavBar.waitForExistence(timeout: Self.shortTimeout) {
            // Fallback: try tapping first tab if Home didn't load
            tabBar.buttons.element(boundBy: 0).tap()
            _ = homeNavBar.waitForExistence(timeout: Self.shortTimeout)
        }

        // Pop any pushed views
        for _ in 0..<2 {
            let backButton = app.buttons["backButton"]
            if backButton.exists, backButton.isHittable {
                backButton.tap()
            } else {
                break
            }
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
        let searchTab = app.tabBars.buttons["Search"]
        if searchTab.exists, !searchTab.isSelected {
            searchTab.tap()
        }
        _ = app.navigationBars["Search"].waitForExistence(timeout: Self.shortTimeout)
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
    func waitForHomeContent(timeout: TimeInterval = 10) -> Bool {
        let contentIndicators = [
            app.staticTexts["Breaking News"],
            app.staticTexts["Top Headlines"],
            app.staticTexts["Unable to Load News"],
            app.staticTexts["No News Available"],
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
