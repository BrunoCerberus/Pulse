import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Default timeout for element existence checks (reduced from 20s)
    static let defaultTimeout: TimeInterval = 8

    /// Short timeout for quick checks
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
            var attempts = 0
            while attempts < 3 && !tabBar.exists {
                let backButton = app.buttons["backButton"]
                if backButton.exists {
                    backButton.tap()
                } else {
                    app.swipeRight()
                }
                usleep(100_000)
                attempts += 1
                _ = tabBar.waitForExistence(timeout: Self.shortTimeout)
            }
        }
        guard tabBar.exists else { return }

        let homeTab = tabBar.buttons["Home"]
        let homeTabFallback = tabBar.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'home' OR identifier CONTAINS[c] 'home' OR identifier CONTAINS[c] 'newspaper'")
        ).firstMatch
        let firstTab = tabBar.buttons.element(boundBy: 0)

        if homeTab.waitForExistence(timeout: Self.shortTimeout) {
            if !homeTab.isSelected {
                homeTab.tap()
            }
        } else if homeTabFallback.waitForExistence(timeout: Self.shortTimeout) {
            if !homeTabFallback.isSelected {
                homeTabFallback.tap()
            }
        } else if firstTab.exists {
            firstTab.tap()
        }

        let homeNavBar = app.navigationBars["Pulse"]
        let gearButton = app.navigationBars.buttons["gearshape"]
        if !homeNavBar.exists && !gearButton.exists {
            for button in tabBar.buttons.allElementsBoundByIndex {
                if button.isSelected {
                    continue
                }
                button.tap()
                if homeNavBar.waitForExistence(timeout: Self.shortTimeout) || gearButton.exists {
                    break
                }
            }
        }

        // Pop any pushed views by tapping back until we're at root
        var attempts = 0
        while attempts < 3 {
            let backButtons = app.navigationBars.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'back' OR identifier == 'backButton'")
            )
            if let backButton = backButtons.allElementsBoundByIndex.first, backButton.exists, backButton.isHittable {
                backButton.tap()
                usleep(100_000) // 0.1 second
                attempts += 1
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
        // Try standard Search tab first
        let searchTab = app.tabBars.buttons["Search"]
        if searchTab.waitForExistence(timeout: Self.shortTimeout) {
            if !searchTab.isSelected {
                searchTab.tap()
            }
            // Wait for Search view to load
            _ = app.navigationBars["Search"].waitForExistence(timeout: Self.defaultTimeout)
            return
        }

        // Fallback to predicate search
        let searchTabAlt = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")
        ).firstMatch
        if searchTabAlt.waitForExistence(timeout: Self.shortTimeout) {
            searchTabAlt.tap()
            _ = app.navigationBars["Search"].waitForExistence(timeout: Self.defaultTimeout)
        }
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        navigateToTab("Home")
        // Wait for Home to fully load
        _ = app.navigationBars["Pulse"].waitForExistence(timeout: Self.defaultTimeout)

        let gearButton = app.navigationBars.buttons["gearshape"]
        if gearButton.waitForExistence(timeout: Self.shortTimeout) {
            gearButton.tap()
            // Wait for Settings to open
            _ = app.navigationBars["Settings"].waitForExistence(timeout: Self.defaultTimeout)
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

    /// Wait for content to load (articles, error, or empty state)
    func waitForHomeContent(timeout: TimeInterval = 10) -> Bool {
        let contentIndicators = [
            app.staticTexts["Breaking News"],
            app.staticTexts["Top Headlines"],
            app.staticTexts["Unable to Load News"],
            app.staticTexts["No News Available"],
        ]

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if contentIndicators.contains(where: { $0.exists }) {
                return true
            }
            usleep(200_000) // 0.2 second - faster polling
        }
        return false
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
            usleep(150_000) // 0.15 second
            if element.exists, element.isHittable {
                return true
            }
        }
        return false
    }
}
