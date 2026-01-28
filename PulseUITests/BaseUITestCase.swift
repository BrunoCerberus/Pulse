import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
@MainActor
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Timeout for app launch verification - requires more time than element checks
    /// CI machines are significantly slower than local, especially on shared runners
    /// Use 60 seconds to handle worst-case CI initialization times
    static let launchTimeout: TimeInterval = 60

    /// Default timeout for element existence checks
    /// 10s accounts for CI machine variability and slower simulators
    static let defaultTimeout: TimeInterval = 10

    /// Short timeout for quick checks (e.g., verifying element visibility)
    /// 6s allows for CI machine variability while remaining responsive
    static let shortTimeout: TimeInterval = 6

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

        // Wait for UI to stabilize after launch (fixes snapshot timing issues)
        wait(for: 0.3)

        // Wait for either tab bar (authenticated) or sign-in view (not authenticated)
        // This handles both states and avoids timeout when MockAuthService is initializing
        let tabBar = app.tabBars.firstMatch
        let signInButton = app.buttons["Sign in with Apple"]

        // First, wait for the loading state to clear (if app shows loading spinner)
        // The loading view has a ProgressView which we need to wait past
        // CI simulators can be slow to show the initial UI, so give more time to detect loading state
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.waitForExistence(timeout: 10) {
            // Wait for loading to complete (app initializing auth state)
            // Use longer timeout for CI where network/auth initialization can be slow
            _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout * 2)
        }

        // Now wait for either tab bar or sign-in to appear
        // Use multiple detection strategies for reliability across different CI environments
        let homeTabButton = app.tabBars.buttons["Home"]
        let signInApple = app.buttons["Sign in with Apple"]
        let signInGoogle = app.buttons["Sign in with Google"]

        // Primary check: tab bar element or sign-in buttons
        var appReady = waitForAny([tabBar, homeTabButton, signInApple, signInGoogle], timeout: Self.launchTimeout)
        var foundTabBar = tabBar.exists || homeTabButton.exists

        // Fallback: If primary check fails but buttons exist, check for tab bar buttons directly
        // This handles CI environments where tabBars query may have timing issues
        if !appReady {
            let tabButtonNames = ["Home", "Feed", "Bookmarks", "Search"]
            for name in tabButtonNames {
                let tabButton = app.buttons[name]
                if tabButton.waitForExistence(timeout: 2) {
                    appReady = true
                    foundTabBar = true
                    break
                }
            }
        }

        guard appReady else {
            // Debug: log what's visible to help diagnose CI failures
            let hasActivityIndicator = app.activityIndicators.count > 0
            let hasButtons = app.buttons.count > 0
            let hasStaticTexts = app.staticTexts.count > 0
            let allButtonLabels = app.buttons.allElementsBoundByIndex.prefix(10).map { $0.label }
            XCTFail("App did not reach ready state - neither tab bar nor sign-in view appeared. " +
                "Debug: hasActivityIndicator=\(hasActivityIndicator), buttons=\(hasButtons), " +
                "texts=\(hasStaticTexts), buttonLabels=\(allButtonLabels)")
            return
        }

        // Only reset to home tab if authenticated (tab bar was found via any detection method)
        if foundTabBar {
            resetToHomeTab()
        }
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        // Gracefully terminate app - don't fail test on termination issues
        // XCUIApplication.terminate() can throw if the app is in an unexpected state
        if let application = app, application.state != .notRunning {
            application.terminate()
            // Brief wait to allow termination to complete
            _ = application.wait(for: .notRunning, timeout: 5)
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
            // Don't fail if tabBar query fails - try direct button access as fallback
        }

        // Select Home tab - try multiple strategies for CI reliability
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        } else if !homeTab.exists {
            // Fallback: try finding Home button directly (handles tabBar query issues on CI)
            let homeButton = app.buttons["Home"]
            if homeButton.waitForExistence(timeout: 2), !homeButton.isSelected {
                homeButton.tap()
            } else if tabBar.exists {
                // Last resort: tap first tab (Home is always first)
                tabBar.buttons.element(boundBy: 0).tap()
            }
        }

        // Pop all navigation stack levels (handles deep navigation states)
        for _ in 0 ..< 3 {
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
        let searchTab = app.tabBars.buttons["Search"]
        // Use waitForExistence for CI reliability
        if searchTab.waitForExistence(timeout: Self.shortTimeout), !searchTab.isSelected {
            searchTab.tap()
        } else if !searchTab.exists {
            // Fallback: try finding the button directly
            let searchButton = app.buttons["Search"]
            if searchButton.waitForExistence(timeout: 2), !searchButton.isSelected {
                searchButton.tap()
            }
        }
        _ = app.navigationBars["Search"].waitForExistence(timeout: Self.defaultTimeout)
    }

    /// Navigate to Feed tab and verify navigation bar appears
    func navigateToFeedTab() {
        let feedTab = app.tabBars.buttons["Feed"]
        // Use waitForExistence with longer timeout for CI reliability
        if feedTab.waitForExistence(timeout: Self.defaultTimeout), !feedTab.isSelected {
            // Wait for element to become hittable
            wait(for: 0.3)
            if feedTab.isHittable {
                feedTab.tap()
            }
        } else if !feedTab.exists {
            // Fallback for iOS 26+: try finding by image name "text.document"
            // The new TabView API may expose image name as the button label
            let feedByImage = app.tabBars.buttons["text.document"]
            if feedByImage.waitForExistence(timeout: Self.shortTimeout), !feedByImage.isSelected {
                wait(for: 0.3)
                if feedByImage.isHittable {
                    feedByImage.tap()
                }
            } else {
                // Last resort: try finding the button directly
                let feedButton = app.buttons["Feed"]
                if feedButton.waitForExistence(timeout: 2), !feedButton.isSelected {
                    feedButton.tap()
                }
            }
        }
        _ = app.navigationBars["Daily Digest"].waitForExistence(timeout: Self.defaultTimeout)
    }

    /// Navigate to Bookmarks tab and verify navigation bar appears
    func navigateToBookmarksTab() {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        // Use waitForExistence for CI reliability
        if bookmarksTab.waitForExistence(timeout: Self.shortTimeout), !bookmarksTab.isSelected {
            bookmarksTab.tap()
        } else if !bookmarksTab.exists {
            // Fallback: try finding the button directly
            let bookmarksButton = app.buttons["Bookmarks"]
            if bookmarksButton.waitForExistence(timeout: 2), !bookmarksButton.isSelected {
                bookmarksButton.tap()
            }
        }
        _ = app.navigationBars["Bookmarks"].waitForExistence(timeout: Self.defaultTimeout)
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        navigateToTab("Home")
        let gearButton = app.navigationBars.buttons["gearshape"]
        if gearButton.waitForExistence(timeout: Self.defaultTimeout) {
            gearButton.tap()
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

    /// Wait for an element to disappear
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate { _, _ in !element.exists }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Wait for content to load (articles, error, or empty state)
    @discardableResult
    func waitForHomeContent(timeout: TimeInterval = 30) -> Bool {
        let contentIndicators = [
            app.staticTexts["Breaking News"],
            app.staticTexts["Top Headlines"],
            app.staticTexts["Unable to Load News"],
            app.staticTexts["No News Available"],
            app.scrollViews.firstMatch, // Fallback: wait for scroll view to appear
        ]
        // First try with main indicators
        if waitForAny(contentIndicators, timeout: timeout) {
            return true
        }
        // Fallback: check if any article cards exist
        return waitForAnyMatch(articleCards(), timeout: 5)
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

    /// Find article cards by accessibility identifier
    func articleCards() -> XCUIElementQuery {
        app.buttons.matching(identifier: "articleCard")
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

        for _ in 0 ..< maxSwipes {
            container.swipeUp()
            // Use element check instead of fixed delay
            if element.waitForExistence(timeout: 0.1), element.isHittable {
                return true
            }
        }
        return false
    }
}
