import XCTest

/// Optimized base class for UI tests that minimizes app launch overhead.
/// Uses class-level setup to launch app once per test class instead of per test.
class BaseUITestCase: XCTestCase {
    /// Shared app instance - launched once per test class
    static var app: XCUIApplication!

    /// Tracks if app was launched for this class
    private static var isAppLaunched = false

    /// Default timeout for element existence checks (reduced from 20s)
    static let defaultTimeout: TimeInterval = 8

    /// Short timeout for quick checks
    static let shortTimeout: TimeInterval = 3

    /// Instance accessor for the shared app
    var app: XCUIApplication {
        Self.app
    }

    // MARK: - Class-level Setup (runs once per test class)

    override class func setUp() {
        super.setUp()

        // Launch app once for entire test class
        if !isAppLaunched {
            app = XCUIApplication()

            // Speed optimizations
            app.launchEnvironment["UI_TESTING"] = "1"
            app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"

            // Launch arguments to speed up tests
            app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
            app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]

            app.launch()
            isAppLaunched = true

            // Wait for app to be ready (once per class)
            _ = app.wait(for: .runningForeground, timeout: 15.0)
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 15.0)
        }
    }

    override class func tearDown() {
        // Terminate app after all tests in this class complete
        if isAppLaunched, app?.state != .notRunning {
            app.terminate()
        }
        isAppLaunched = false
        app = nil
        super.tearDown()
    }

    // MARK: - Instance-level Setup (runs before each test)

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        // Ensure app is in a clean state
        resetToHomeTab()
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Navigation Helpers

    /// Reset to Home tab to start each test from a known state
    func resetToHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
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
        let searchTab = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")
        ).firstMatch
        if searchTab.waitForExistence(timeout: Self.shortTimeout) {
            searchTab.tap()
        }
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        navigateToTab("Home")
        let gearButton = app.navigationBars.buttons["gearshape"]
        if gearButton.waitForExistence(timeout: Self.shortTimeout) {
            gearButton.tap()
        }
        _ = app.navigationBars["Settings"].waitForExistence(timeout: Self.shortTimeout)
    }

    // MARK: - Wait Helpers

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
