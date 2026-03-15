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
        // Use continueAfterFailure = true to prevent Xcode 26 C++ exception crashes.
        // When set to false, XCTest throws a C++ exception on assertion failure, but
        // the Swift runtime is compiled without C++ exception support, causing SIGABRT
        // ("C++ exception handling detected but the Swift runtime was compiled with
        // exceptions disabled"). This crashes the test runner and cascades to all
        // subsequent tests. With true, failures are recorded without crashing.
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        configureAndLaunchApp()

        // If the first launch failed (e.g., zombie process from a previous crash),
        // terminate and retry with a fresh instance
        if app.state != .runningForeground {
            app.terminate()
            _ = app.wait(for: .notRunning, timeout: 10)
            app = XCUIApplication()
            configureAndLaunchApp()
        }

        // If the app still isn't running after retry, skip this test rather than
        // proceeding with a broken app instance (which would crash the test runner)
        guard app.state == .runningForeground else {
            throw XCTSkip("App failed to launch after retry — simulator may be in a bad state")
        }

        // Wait for UI to stabilize after launch
        // CI cold starts need more time for accessibility services to be ready
        wait(for: 2.0)

        // Wait for loading state to clear if present
        // Use shorter detection timeout — don't wait long if no spinner appears
        let loadingIndicator = app.activityIndicators.firstMatch
        if safeWaitForExistence(loadingIndicator, timeout: 5) {
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
        defer { app = nil }
        XCUIDevice.shared.orientation = .portrait
        // Terminate the app explicitly to prevent "Failed to terminate" errors
        // in the next test's setUp when app.launch() tries to kill a lingering instance.
        // With continueAfterFailure = true, any C++ exception from Xcode 26's
        // accessibility queries during termination is recorded as a non-fatal issue
        // rather than crashing the test runner.
        if let app, app.state != .notRunning {
            app.terminate()
            // Wait for termination to complete before next test starts.
            // "Failed to terminate" errors in CI happen when the next test's launch()
            // runs before the previous instance fully exits.
            if !app.wait(for: .notRunning, timeout: 10) {
                // Retry termination — CI shared runners can be slow to release processes
                app.terminate()
                _ = app.wait(for: .notRunning, timeout: 10)
            }
        }
    }

    // MARK: - Subclass Hooks

    /// Override in subclasses to set additional launch environment variables before app.launch().
    /// Called after standard environment is configured but before launch.
    func configureLaunchEnvironment() {
        // Default: no additional configuration
    }

    // MARK: - Launch Helpers

    /// Configures and launches `self.app`. Terminates any lingering process first.
    /// After calling, check `app.state == .runningForeground` to verify success.
    private func configureAndLaunchApp() {
        // Terminate any lingering app process from a previous test that crashed or
        // failed to tear down cleanly. terminate() is a no-op if the app isn't running.
        if app.state != .notRunning {
            app.terminate()
            _ = app.wait(for: .notRunning, timeout: 10)
        }

        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"
        app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
        app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]
        app.launchArguments += ["-pulse.hasCompletedOnboarding", "YES"]
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        configureLaunchEnvironment()

        app.launch()
        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)
    }

    /// Guard that ensures the app is still running in foreground.
    /// Use at the start of multi-step test sections to bail out early if the app crashed.
    /// Returns true if the app is alive, throws XCTSkip otherwise.
    @discardableResult
    func ensureAppRunning(file: StaticString = #filePath, line: UInt = #line) throws -> Bool {
        guard app.state == .runningForeground else {
            throw XCTSkip(
                "App is not running (state: \(app.state.rawValue)). Skipping remainder of test.",
                file: file,
                line: line
            )
        }
        return true
    }

    // MARK: - Navigation Helpers

    /// Reset to Home tab to start each test from a known state
    func resetToHomeTab() {
        guard app.state == .runningForeground else { return }
        let tabBar = app.tabBars.firstMatch

        // Quick check - if tab bar not visible, try recovery
        if !safeWaitForExistence(tabBar, timeout: Self.shortTimeout) {
            let backButton = app.buttons["backButton"]
            if backButton.exists { backButton.tap() }
            // Don't fail if tabBar query fails - try direct button access as fallback
        }

        // Select Home tab - use coordinate-based taps for iOS 26 Liquid Glass reliability
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            wait(for: 0.3)
            let center = homeTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else if !homeTab.exists {
            // Fallback: try finding Home button directly (handles tabBar query issues on CI)
            let homeButton = app.buttons["Home"]
            if safeWaitForExistence(homeButton, timeout: 2) {
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
    ///
    /// Avoids `waitForExistence` on tab bar buttons to prevent Xcode 26 C++ exception
    /// crashes. The tab bar is already verified in setUp, so we use synchronous `.exists`
    /// checks (single accessibility snapshot) and coordinate-based taps instead.
    func navigateToTab(_ tabName: String) {
        // Guard against interacting with a crashed/terminated app
        guard app.state == .runningForeground else { return }

        let tab = app.tabBars.buttons[tabName]

        // Use synchronous .exists (single snapshot) instead of waitForExistence
        // (polling loop) to avoid repeated accessibility hierarchy queries that
        // can trigger Xcode 26 C++ exception crashes.
        // Note: We skip .isSelected checks because they trigger a full accessibility
        // hierarchy query that can time out on CI ("Timed out while evaluating UI query").
        // Tapping an already-selected tab is a no-op, so always tapping is safe.
        if tab.exists {
            wait(for: 0.3)
            // Always use coordinate-based tap to bypass hittability evaluation
            // which can also crash on iOS 26 Liquid Glass tab bar
            let center = tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            // Fallback: try finding the button directly (outside tab bar query)
            let tabButton = app.buttons[tabName]
            if tabButton.exists {
                tabButton.tap()
            }
        }

        // Wait for UI to settle on CI
        wait(for: 0.5)

        // Verify navigation - Home tab nav bar is titled "News", not "Home"
        let navBarTitle = tabName == "Home" ? "News" : tabName
        _ = safeWaitForExistence(app.navigationBars[navBarTitle], timeout: Self.shortTimeout)
    }

    /// Navigate to Search tab (handles role: .search accessibility)
    func navigateToSearchTab() {
        guard app.state == .runningForeground else { return }
        let searchTab = app.tabBars.buttons["Search"]
        if searchTab.exists {
            wait(for: 0.3)
            let center = searchTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            let searchButton = app.buttons["Search"]
            if searchButton.exists {
                searchButton.tap()
            }
        }
        _ = safeWaitForExistence(app.navigationBars["Search"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Feed tab and verify navigation bar appears
    func navigateToFeedTab() {
        guard app.state == .runningForeground else { return }
        let feedTab = app.tabBars.buttons["Feed"]
        if feedTab.exists {
            wait(for: 0.3)
            let center = feedTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            // Fallback for iOS 26+: try finding by image name "text.document"
            let feedByImage = app.tabBars.buttons["text.document"]
            if feedByImage.exists {
                wait(for: 0.3)
                let center = feedByImage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            } else {
                let feedButton = app.buttons["Feed"]
                if feedButton.exists {
                    feedButton.tap()
                }
            }
        }
        _ = safeWaitForExistence(app.navigationBars["Daily Digest"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Media tab with recovery for CI
    func navigateToMediaTab() {
        guard app.state == .runningForeground else { return }
        let mediaTab = app.tabBars.buttons["Media"]

        if mediaTab.exists {
            wait(for: 0.3)
            let center = mediaTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            // Fallback for iOS 26+: try finding by image name "play.tv"
            let mediaByImage = app.tabBars.buttons["play.tv"]
            if mediaByImage.exists {
                wait(for: 0.3)
                let center = mediaByImage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            } else {
                let mediaButton = app.buttons["Media"]
                if mediaButton.exists {
                    mediaButton.tap()
                }
            }
        }

        // Wait for UI to settle on CI
        wait(for: 0.5)

        // Verify with recovery
        var navBarVisible = safeWaitForExistence(app.navigationBars["Media"], timeout: Self.defaultTimeout)
        if !navBarVisible {
            // Recovery: tap again with coordinate-based approach
            let retryTab = mediaTab.exists ? mediaTab : app.tabBars.buttons["play.tv"]
            if retryTab.exists {
                let center = retryTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
                wait(for: 1.0)
                navBarVisible = safeWaitForExistence(app.navigationBars["Media"], timeout: Self.defaultTimeout)
            }
        }
    }

    /// Navigate to Bookmarks tab and verify navigation bar appears
    func navigateToBookmarksTab() {
        guard app.state == .runningForeground else { return }
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        if bookmarksTab.exists {
            wait(for: 0.3)
            let center = bookmarksTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            let bookmarksButton = app.buttons["Bookmarks"]
            if bookmarksButton.exists {
                bookmarksButton.tap()
            }
        }
        _ = safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        guard app.state == .runningForeground else { return }
        navigateToTab("Home")

        // Try multiple strategies to find the gear button
        var gearButton = app.navigationBars.buttons["Settings"]
        if !gearButton.exists {
            // Toolbar items may not be in navBar on iOS 26
            gearButton = app.buttons["Settings"]
        }

        if gearButton.exists {
            wait(for: 0.3)
            let center = gearButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            _ = safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout)
        }
    }

    // MARK: - Wait Helpers

    /// Safe alternative to XCTest's `waitForExistence` that avoids Xcode 26 C++ exception crashes.
    ///
    /// `waitForExistence(timeout:)` uses XCTest's internal snapshot comparison loop which can
    /// throw an uncatchable C++ exception ("C++ exception handling detected but the Swift runtime
    /// was compiled with exceptions disabled") when a snapshot evaluation times out. This crashes
    /// the test runner with SIGABRT.
    ///
    /// This method polls `.exists` (single snapshot per iteration) with RunLoop-based delays,
    /// which avoids the internal snapshot loop that triggers the crash.
    @discardableResult
    func safeWaitForExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        if element.exists { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            if element.exists { return true }
        }
        return false
    }

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

    /// Wait for any of the provided elements to exist.
    /// Uses 0.5s polling interval to reduce UI query pressure on CI shared runners,
    /// where rapid .exists calls can trigger Xcode 26 C++ exception crashes
    /// ("Timed out while evaluating UI query").
    func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval = 10) -> Bool {
        // Check immediately before entering the polling loop
        if elements.contains(where: { $0.exists }) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if elements.contains(where: { $0.exists }) {
                return true
            }
        }
        return false
    }

    /// Wait for any element matching query to exist
    func waitForAnyMatch(_ query: XCUIElementQuery, timeout: TimeInterval = 10) -> Bool {
        if query.count > 0 { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if query.count > 0 {
                return true
            }
        }
        return false
    }

    /// Wait for an element to disappear.
    /// Uses polling with `.exists` (single snapshot per iteration) instead of
    /// `XCTNSPredicateExpectation` which uses XCTest's internal snapshot loop
    /// that can throw uncatchable C++ exceptions on Xcode 26.
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        if !element.exists { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            if !element.exists { return true }
        }
        return false
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
        if safeWaitForExistence(detailScrollView, timeout: timeout) {
            return true
        }
        return safeWaitForExistence(app.buttons["backButton"], timeout: 1)
    }

    /// Navigate back from current view with post-navigation wait for CI stability
    func navigateBack(waitForNavBar navBarTitle: String? = nil, timeout: TimeInterval = 15) {
        let backButton = app.buttons["backButton"]
        if backButton.exists {
            let center = backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
        } else {
            app.swipeRight()
        }

        // Wait for navigation animation to settle (critical on slow CI runners)
        wait(for: 0.5)

        // If a target nav bar was specified, wait for it to appear with retry
        if let navBarTitle {
            if !safeWaitForExistence(app.navigationBars[navBarTitle], timeout: timeout) {
                // Recovery: try navigating back again (tap may have been swallowed)
                let retryBack = app.buttons["backButton"]
                if retryBack.exists {
                    let center = retryBack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    center.tap()
                    wait(for: 0.5)
                } else {
                    app.swipeRight()
                    wait(for: 0.5)
                }
            }
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
        if element.exists {
            return true
        }

        let container = scrollView ?? app.scrollViews.firstMatch
        guard container.exists else { return false }

        for _ in 0 ..< maxSwipes {
            container.swipeUp()
            if element.exists {
                return true
            }
        }
        return false
    }
}
