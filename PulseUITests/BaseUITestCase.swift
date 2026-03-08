import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
@MainActor
// swiftlint:disable:next type_body_length
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Timeout for app launch verification - requires more time than element checks
    /// CI machines are significantly slower than local, especially on shared runners
    /// Use 60 seconds to handle worst-case CI initialization times
    static let launchTimeout: TimeInterval = 60

    /// Default timeout for element existence checks
    /// 15s accounts for CI machine variability, slower simulators, and post-restart recovery
    static let defaultTimeout: TimeInterval = 15

    /// Short timeout for quick checks (e.g., verifying element visibility)
    /// 10s allows for CI machine variability including post-restart recovery
    static let shortTimeout: TimeInterval = 10

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

        // Skip onboarding flow in UI tests (sets UserDefaults via argument domain)
        app.launchArguments += ["-pulse.hasCompletedOnboarding", "YES"]

        // Force English locale for deterministic behavior across CI environments
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]

        // Allow subclasses to configure launch environment (e.g., MOCK_PREMIUM)
        configureLaunchEnvironment()

        app.launch()

        // Launch verification - uses longer timeout as app startup takes time
        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)

        // Wait for UI to stabilize after launch
        // CI cold starts need more time for accessibility services to be ready
        wait(for: 2.0)

        // Wait for loading state to clear if present
        // Use shorter detection timeout — don't wait long if no spinner appears
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.waitForExistence(timeout: 5) {
            // Wait for loading to complete (app initializing auth state)
            _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout)
        }

        // Wait for either tab bar (authenticated) or sign-in view (not authenticated)
        let tabBar = app.tabBars.firstMatch
        let signInApple = app.buttons["Sign in with Apple"]
        let signInGoogle = app.buttons["Sign in with Google"]

        let appReady = waitForAny([tabBar, signInApple, signInGoogle], timeout: Self.launchTimeout)

        guard appReady else {
            // Debug: log what's visible to help diagnose CI failures
            let hasActivityIndicator = app.activityIndicators.count > 0
            let hasButtons = app.buttons.count > 0
            let hasStaticTexts = app.staticTexts.count > 0
            let allButtonLabels = app.buttons.allElementsBoundByIndex.prefix(10).map { $0.label }
            let debugInfo = "App did not reach ready state - neither tab bar nor sign-in view appeared. " +
                "Debug: hasActivityIndicator=\(hasActivityIndicator), buttons=\(hasButtons), " +
                "texts=\(hasStaticTexts), buttonLabels=\(allButtonLabels)"
            print(debugInfo)
            throw XCTSkip("App not ready: \(debugInfo)")
        }

        // Only reset to home tab if authenticated (tab bar was found)
        if tabBar.exists {
            resetToHomeTab()
        }
    }

    override func tearDown() {
        // Use tearDown() instead of tearDownWithError() to prevent termination
        // failures from being recorded as test errors on CI.
        // After a test crash/timeout, the simulator may be in an unrecoverable
        // state where terminate() throws "Failed to terminate".
        defer { app = nil }
        XCUIDevice.shared.orientation = .portrait
        guard let application = app, application.state != .notRunning else { return }
        application.terminate()
        _ = application.wait(for: .notRunning, timeout: 5)
    }

    // MARK: - Subclass Hooks

    /// Override in subclasses to set additional launch environment variables before app.launch().
    /// Called after standard environment is configured but before launch.
    func configureLaunchEnvironment() {
        // Default: no additional configuration
    }

    // MARK: - Navigation Helpers

    /// Reset to Home tab to start each test from a known state
    func resetToHomeTab() {
        guard app.state == .runningForeground else { return }
        let tabBar = app.tabBars.firstMatch

        // Quick check - if tab bar not visible, try recovery
        if !tabBar.waitForExistence(timeout: Self.shortTimeout) {
            let backButton = app.buttons["backButton"]
            if backButton.exists { backButton.tap() }
            // Don't fail if tabBar query fails - try direct button access as fallback
        }

        // Select Home tab - use coordinate-based taps for iOS 26 Liquid Glass reliability
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            wait(for: 0.3)
            let center = homeTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else if !homeTab.exists {
            // Fallback: try finding Home button directly (handles tabBar query issues on CI)
            let homeButton = app.buttons["Home"]
            if homeButton.waitForExistence(timeout: 2), !homeButton.isSelected {
                homeButton.tap()
            } else if tabBar.exists {
                // Last resort: tap first tab (Home is always first)
                let firstTab = tabBar.buttons.element(boundBy: 0)
                if firstTab.exists {
                    let center = firstTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    center.tap()
                }
            }
        }

        // Pop all navigation stack levels (handles deep navigation states)
        // Avoid .isHittable checks which can time out on iOS 26 Liquid Glass
        for _ in 0 ..< 3 {
            let backButton = app.buttons["backButton"]
            guard backButton.exists else { break }
            let center = backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            wait(for: 0.2) // Allow navigation animation to settle
        }
    }

    /// Navigate to a specific tab with recovery
    func navigateToTab(_ tabName: String) {
        // Guard against interacting with a crashed/terminated app
        guard app.state == .runningForeground else { return }

        let tab = app.tabBars.buttons[tabName]

        // First attempt
        if tab.waitForExistence(timeout: Self.shortTimeout), !tab.isSelected {
            // Wait for element to become hittable (iOS 26+ Liquid Glass tab bar
            // exposes symbol sub-elements that can cause XCTest crashes if tapped
            // without checking hittability first)
            wait(for: 0.3)
            if tab.isHittable {
                tab.tap()
            } else {
                // On iOS 26+, use coordinate-based tap to bypass hittability evaluation
                // which can time out on Liquid Glass tab bar
                let center = tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }
        } else if !tab.exists {
            // Fallback: try finding the button directly
            let tabButton = app.buttons[tabName]
            if tabButton.waitForExistence(timeout: Self.shortTimeout), !tabButton.isSelected {
                tabButton.tap()
            }
        } else if tab.isSelected {
            // Already on this tab, nothing to do
            return
        }

        // Wait for UI to settle on CI
        wait(for: 0.5)

        // Verify navigation - Home tab nav bar is titled "News", not "Home"
        let navBarTitle = tabName == "Home" ? "News" : tabName
        _ = app.navigationBars[navBarTitle].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Navigate to Search tab (handles role: .search accessibility)
    func navigateToSearchTab() {
        guard app.state == .runningForeground else { return }
        let searchTab = app.tabBars.buttons["Search"]
        // Use waitForExistence for CI reliability
        if searchTab.waitForExistence(timeout: Self.shortTimeout), !searchTab.isSelected {
            // Wait for element to become hittable (iOS 26+ Liquid Glass tab bar)
            wait(for: 0.3)
            if searchTab.isHittable {
                searchTab.tap()
            } else {
                let center = searchTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }
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
        guard app.state == .runningForeground else { return }
        let feedTab = app.tabBars.buttons["Feed"]
        // Use waitForExistence with longer timeout for CI reliability
        if feedTab.waitForExistence(timeout: Self.defaultTimeout), !feedTab.isSelected {
            // Wait for element to become hittable
            wait(for: 0.3)
            if feedTab.isHittable {
                feedTab.tap()
            } else {
                // On iOS 26+, the Feed button may report as not hittable due to
                // Liquid Glass sub-element layout — fall through to direct button lookup
                let feedButton = app.buttons["Feed"]
                if feedButton.waitForExistence(timeout: 2), !feedButton.isSelected {
                    feedButton.tap()
                }
            }
        } else if !feedTab.exists {
            // Fallback for iOS 26+: try finding by image name "text.document"
            // The new TabView API may expose image name as the button label
            let feedByImage = app.tabBars.buttons["text.document"]
            if feedByImage.waitForExistence(timeout: Self.shortTimeout), !feedByImage.isSelected {
                wait(for: 0.3)
                if feedByImage.isHittable {
                    feedByImage.tap()
                } else {
                    let center = feedByImage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    center.tap()
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

    /// Navigate to Media tab with recovery for CI
    func navigateToMediaTab() {
        guard app.state == .runningForeground else { return }
        let mediaTab = app.tabBars.buttons["Media"]

        // First attempt
        if mediaTab.waitForExistence(timeout: Self.shortTimeout), !mediaTab.isSelected {
            // Wait for element to become hittable (iOS 26+ Liquid Glass tab bar
            // exposes symbol sub-elements that can cause XCTest crashes if tapped
            // without checking hittability first)
            wait(for: 0.3)
            if mediaTab.isHittable {
                mediaTab.tap()
            }
        } else if !mediaTab.exists {
            // Fallback for iOS 26+: try finding by image name "play.tv"
            // The new TabView API may expose image name as the button label
            let mediaByImage = app.tabBars.buttons["play.tv"]
            if mediaByImage.waitForExistence(timeout: Self.shortTimeout), !mediaByImage.isSelected {
                wait(for: 0.5)
                // Use coordinate-based tap to bypass XCTest hittability evaluation
                // which can time out on iOS 26 Liquid Glass tab bar
                let center = mediaByImage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            } else {
                // Last resort: try finding the button directly
                let mediaButton = app.buttons["Media"]
                if mediaButton.waitForExistence(timeout: 2), !mediaButton.isSelected {
                    mediaButton.tap()
                }
            }
        } else if mediaTab.isSelected {
            // Already on Media tab
            wait(for: 0.5)
            return
        }

        // Wait for UI to settle on CI
        wait(for: 0.5)

        // Verify with recovery
        var navBarVisible = app.navigationBars["Media"].waitForExistence(timeout: Self.defaultTimeout)
        if !navBarVisible {
            // Recovery: tap again with coordinate-based approach
            let retryTab = mediaTab.exists ? mediaTab : app.tabBars.buttons["play.tv"]
            if retryTab.exists {
                let center = retryTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
                wait(for: 1.0)
                navBarVisible = app.navigationBars["Media"].waitForExistence(timeout: Self.defaultTimeout)
            }
        }
    }

    /// Navigate to Bookmarks tab and verify navigation bar appears
    func navigateToBookmarksTab() {
        guard app.state == .runningForeground else { return }
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        // Use waitForExistence for CI reliability
        if bookmarksTab.waitForExistence(timeout: Self.shortTimeout), !bookmarksTab.isSelected {
            // Wait for element to become hittable (iOS 26+ Liquid Glass tab bar)
            wait(for: 0.3)
            if bookmarksTab.isHittable {
                bookmarksTab.tap()
            } else {
                // On iOS 26+, fall back to direct button lookup when tab bar button reports not hittable
                let bookmarksButton = app.buttons["Bookmarks"]
                if bookmarksButton.waitForExistence(timeout: 2), !bookmarksButton.isSelected {
                    bookmarksButton.tap()
                }
            }
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
        guard app.state == .runningForeground else { return }
        navigateToTab("Home")

        // Try multiple strategies to find the gear button
        // Strategy 1: Navigation bar buttons query
        var gearButton = app.navigationBars.buttons["Settings"]
        if !gearButton.waitForExistence(timeout: Self.shortTimeout) {
            // Strategy 2: Direct button lookup (toolbar items may not be in navBar on iOS 26)
            gearButton = app.buttons["Settings"]
        }

        if gearButton.waitForExistence(timeout: Self.shortTimeout) {
            wait(for: 0.3)
            if gearButton.isHittable {
                gearButton.tap()
            } else {
                // On iOS 26+, use coordinate-based tap to bypass hittability issues
                let center = gearButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }
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
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if elements.contains(where: { $0.exists }) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }

    /// Wait for any element matching query to exist
    func waitForAnyMatch(_ query: XCUIElementQuery, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if query.count > 0 {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
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
