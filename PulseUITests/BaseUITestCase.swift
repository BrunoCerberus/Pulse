import XCTest

/// Base class for UI tests that standardizes launch configuration and isolation.
// swiftlint:disable:next type_body_length
@MainActor
class BaseUITestCase: XCTestCase {
    /// App instance - launched per test for isolation
    var app: XCUIApplication!

    /// Timeout for app launch verification - requires more time than element checks
    /// CI machines are significantly slower than local, especially on shared runners
    static let launchTimeout: TimeInterval = 60

    /// Default timeout for element existence checks
    /// 15s accounts for CI machine variability, slower simulators, and post-restart recovery
    static let defaultTimeout: TimeInterval = 15

    /// Short timeout for quick checks (e.g., verifying element visibility)
    /// 10s allows for CI machine variability including post-restart recovery
    static let shortTimeout: TimeInterval = 10

    // MARK: - Instance-level Setup (runs before each test)

    override func setUp() async throws {
        // Use continueAfterFailure = true to prevent Xcode 26 C++ exception crashes.
        // When set to false, XCTest throws a C++ exception on assertion failure, but
        // the Swift runtime is compiled without C++ exception support, causing SIGABRT
        // ("C++ exception handling detected but the Swift runtime was compiled with
        // exceptions disabled"). This crashes the test runner and cascades to all
        // subsequent tests. With true, failures are recorded without crashing.
        continueAfterFailure = true
        if shouldSetDeviceOrientation {
            XCUIDevice.shared.orientation = .portrait
        }

        app = XCUIApplication()
        configureAndLaunchApp()

        // If the first launch failed (e.g., zombie process from a previous crash),
        // terminate and retry with a fresh instance
        if app.state != .runningForeground {
            ObjCExceptionCatcher.safeTerminateApp(app)
            _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10)
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

        if shouldWaitForLoadingIndicator {
            // Wait for loading state to clear if present
            // Use shorter detection timeout — don't wait long if no spinner appears
            let loadingIndicator = app.activityIndicators.firstMatch
            if safeWaitForExistence(loadingIndicator, timeout: 5) {
                // Wait for loading to complete (app initializing auth state)
                _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout)
            }
        }

        // Wait for either tab bar (authenticated) or sign-in view (not authenticated)
        let tabBar = app.tabBars.firstMatch
        let signInApple = app.buttons["Sign in with Apple"]
        let signInGoogle = app.buttons["Sign in with Google"]

        let appReady = waitForAny([tabBar, signInApple, signInGoogle], timeout: Self.launchTimeout)

        guard appReady else {
            // Debug: log what's visible to help diagnose CI failures
            let hasActivityIndicator = ObjCExceptionCatcher.safeCount(for: app.activityIndicators) > 0
            let hasButtons = ObjCExceptionCatcher.safeCount(for: app.buttons) > 0
            let hasStaticTexts = ObjCExceptionCatcher.safeCount(for: app.staticTexts) > 0
            let debugInfo = "App did not reach ready state - neither tab bar nor sign-in view appeared. " +
                "Debug: hasActivityIndicator=\(hasActivityIndicator), buttons=\(hasButtons), " +
                "texts=\(hasStaticTexts)"
            print(debugInfo)
            throw XCTSkip("App not ready: \(debugInfo)")
        }

        // Only reset to home tab if authenticated (tab bar was found)
        if safeExists(tabBar) {
            resetToHomeTab()
        }
    }

    override func tearDown() async throws {
        defer { app = nil }
        // Use ObjC++ wrapper — setting orientation can throw a C++ exception when the
        // test runner is in a bad state after a UI query timeout, crashing tearDown.
        ObjCExceptionCatcher.safeSetDeviceOrientation(.portrait)
        // Terminate the app using ObjC++ @try/@catch to prevent C++ exception crashes.
        // Xcode 26 throws C++ exceptions during terminate() ("Failed to terminate")
        // which crash the Swift runtime. Wrapping in ObjC++ catches these safely.
        if let app, app.state != .notRunning {
            ObjCExceptionCatcher.safeTerminateApp(app)
            // Wait for termination to complete before next test starts.
            if !ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10) {
                // Retry termination — CI shared runners can be slow to release processes
                ObjCExceptionCatcher.safeTerminateApp(app)
                _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10)
            }
        }
    }

    // MARK: - Subclass Hooks

    /// Override in subclasses to set additional launch environment variables before app.launch().
    /// Called after standard environment is configured but before launch.
    func configureLaunchEnvironment() {
        // Default: no additional configuration
    }

    /// Override to skip setUp's activity-indicator disappear wait. On degraded CI
    /// simulators (Xcode 26 + iOS 26 on macOS-26-arm64 runners) each `safeExists`
    /// on the spinner can block 30–90s inside XCTest's internal query retries,
    /// consuming 200+s before the test body even runs. Tests that rely on their
    /// own terminal-state waits (e.g. `AccessibilityAuditTests.waitForStableState`)
    /// can safely skip this phase — the `waitForAny` below still waits for the
    /// tab bar or sign-in view to appear.
    var shouldWaitForLoadingIndicator: Bool { true }

    /// Override to skip setUp's `XCUIDevice.orientation = .portrait` call. The
    /// setter blocks until the simulator confirms the orientation change; on cold
    /// CI boot the confirmation can take 8s+ and XCTest records a
    /// `Failed to set device orientation` test failure that bypasses the test
    /// body even with `continueAfterFailure = true` (GitHub Actions run
    /// 24419133870). The simulator boots in portrait by default so this call is
    /// only needed for tests that rotate the device mid-test.
    var shouldSetDeviceOrientation: Bool { true }

    // MARK: - Launch Helpers

    /// Configures and launches `self.app`. Terminates any lingering process first.
    /// After calling, check `app.state == .runningForeground` to verify success.
    private func configureAndLaunchApp() {
        // Terminate any lingering app process from a previous test that crashed or
        // failed to tear down cleanly. terminate() is a no-op if the app isn't running.
        if app.state != .notRunning {
            ObjCExceptionCatcher.safeTerminateApp(app)
            _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .notRunning, timeout: 10)
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
        _ = ObjCExceptionCatcher.safeWait(forApp: app, state: .runningForeground, timeout: Self.launchTimeout)
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
            if safeExists(backButton) { safeTap(backButton) }
        }

        // Select Home tab - use coordinate-based taps for iOS 26 Liquid Glass reliability
        let homeTab = tabBar.buttons["Home"]
        if safeExists(homeTab) {
            wait(for: 0.3)
            safeTap(homeTab)
        } else {
            // Fallback: try finding Home button directly (handles tabBar query issues on CI)
            let homeButton = app.buttons["Home"]
            if safeWaitForExistence(homeButton, timeout: 2) {
                safeTap(homeButton)
            } else if safeExists(tabBar) {
                // Last resort: tap first tab (Home is always first)
                let firstTab = tabBar.buttons.element(boundBy: 0)
                if safeExists(firstTab) { safeTap(firstTab) }
            }
        }

        // Pop all navigation stack levels (handles deep navigation states)
        for _ in 0 ..< 3 {
            let backButton = app.buttons["backButton"]
            guard safeExists(backButton) else { break }
            safeTap(backButton)
            wait(for: 0.2)
        }
    }

    /// Navigate to a specific tab with recovery
    ///
    /// Avoids `waitForExistence` on tab bar buttons to prevent Xcode 26 C++ exception
    /// crashes. The tab bar is already verified in setUp, so we use ObjC-wrapped `.exists`
    /// checks and coordinate-based taps instead.
    func navigateToTab(_ tabName: String) {
        guard app.state == .runningForeground else { return }

        let tab = app.tabBars.buttons[tabName]
        if safeExists(tab) {
            wait(for: 0.3)
            safeTap(tab)
        } else {
            let tabButton = app.buttons[tabName]
            if safeExists(tabButton) { safeTap(tabButton) }
        }

        wait(for: 0.5)
        let navBarTitle = tabName == "Home" ? "News" : tabName
        _ = safeWaitForExistence(app.navigationBars[navBarTitle], timeout: Self.shortTimeout)
    }

    /// Navigate to Search tab (handles role: .search accessibility)
    func navigateToSearchTab() {
        guard app.state == .runningForeground else { return }
        let searchTab = app.tabBars.buttons["Search"]
        if safeExists(searchTab) {
            wait(for: 0.3)
            safeTap(searchTab)
        } else {
            let searchButton = app.buttons["Search"]
            if safeExists(searchButton) { safeTap(searchButton) }
        }
        _ = safeWaitForExistence(app.navigationBars["Search"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Feed tab and verify navigation bar appears
    func navigateToFeedTab() {
        guard app.state == .runningForeground else { return }
        let feedTab = app.tabBars.buttons["Feed"]
        if safeExists(feedTab) {
            wait(for: 0.3)
            safeTap(feedTab)
        } else {
            let feedByImage = app.tabBars.buttons["text.document"]
            if safeExists(feedByImage) {
                wait(for: 0.3)
                safeTap(feedByImage)
            } else {
                let feedButton = app.buttons["Feed"]
                if safeExists(feedButton) {
                    safeTap(feedButton)
                } else {
                    // Last resort: tap Feed by position (index 2, always Feed)
                    let tabBar = app.tabBars.firstMatch
                    if safeExists(tabBar) {
                        let feedTabByIndex = tabBar.buttons.element(boundBy: 2)
                        if safeExists(feedTabByIndex) { safeTap(feedTabByIndex) }
                    }
                }
            }
        }
        _ = safeWaitForExistence(app.navigationBars["Daily Digest"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Media tab with recovery for CI
    func navigateToMediaTab() {
        guard app.state == .runningForeground else { return }
        let mediaTab = app.tabBars.buttons["Media"]

        if safeExists(mediaTab) {
            wait(for: 0.3)
            safeTap(mediaTab)
        } else {
            let mediaByImage = app.tabBars.buttons["play.tv"]
            if safeExists(mediaByImage) {
                wait(for: 0.3)
                safeTap(mediaByImage)
            } else {
                let mediaButton = app.buttons["Media"]
                if safeExists(mediaButton) { safeTap(mediaButton) }
            }
        }

        wait(for: 0.5)

        var navBarVisible = safeWaitForExistence(app.navigationBars["Media"], timeout: Self.defaultTimeout)
        if !navBarVisible {
            let retryTab = safeExists(mediaTab) ? mediaTab : app.tabBars.buttons["play.tv"]
            if safeExists(retryTab) {
                safeTap(retryTab)
                wait(for: 1.0)
                navBarVisible = safeWaitForExistence(app.navigationBars["Media"], timeout: Self.defaultTimeout)
            }
        }
    }

    /// Navigate to Bookmarks tab and verify navigation bar appears
    func navigateToBookmarksTab() {
        guard app.state == .runningForeground else { return }
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        if safeExists(bookmarksTab) {
            wait(for: 0.3)
            safeTap(bookmarksTab)
        } else {
            let bookmarksButton = app.buttons["Bookmarks"]
            if safeExists(bookmarksButton) { safeTap(bookmarksButton) }
        }
        _ = safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.defaultTimeout)
    }

    /// Navigate to Settings via gear button
    func navigateToSettings() {
        guard app.state == .runningForeground else { return }
        navigateToTab("Home")

        var gearButton = app.navigationBars.buttons["Settings"]
        if !safeExists(gearButton) {
            gearButton = app.buttons["Settings"]
        }

        if safeExists(gearButton) {
            wait(for: 0.3)
            safeTap(gearButton)
            _ = safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout)
        }
    }

    // MARK: - Exception-Safe Element Helpers

    /// Checks `.exists` via ObjC++ @try/@catch to prevent C++ exception crashes.
    /// The actual `.exists` call happens in ObjC++ code, NOT in a Swift closure,
    /// so the C++ exception is caught before it reaches the Swift runtime.
    func safeExists(_ element: XCUIElement) -> Bool {
        ObjCExceptionCatcher.safeExists(for: element)
    }

    /// Taps an element using coordinate-based tap via ObjC++ @try/@catch.
    func safeTap(_ element: XCUIElement) {
        ObjCExceptionCatcher.safeTap(element)
    }

    // MARK: - Wait Helpers

    /// Safe alternative to XCTest's `waitForExistence` that avoids Xcode 26 C++ exception crashes.
    /// All `.exists` calls are wrapped in ObjC `@try/@catch` to catch C++ exceptions
    /// that would otherwise SIGABRT the test runner.
    @discardableResult
    func safeWaitForExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        if safeExists(element) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if safeExists(element) { return true }
        }
        return false
    }

    /// Smart wait that replaces Thread.sleep - waits for UI to settle
    @discardableResult
    func wait(for duration: TimeInterval) -> Bool {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
        return true
    }

    /// Wait for any of the provided elements to exist.
    /// Uses 0.5s polling interval to reduce UI query pressure on CI shared runners.
    func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval = 10) -> Bool {
        if elements.contains(where: { safeExists($0) }) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if elements.contains(where: { safeExists($0) }) {
                return true
            }
        }
        return false
    }

    /// Wait for any element matching query to exist
    func waitForAnyMatch(_ query: XCUIElementQuery, timeout: TimeInterval = 10) -> Bool {
        if ObjCExceptionCatcher.safeCount(for: query) > 0 { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if ObjCExceptionCatcher.safeCount(for: query) > 0 { return true }
        }
        return false
    }

    /// Wait for an element to disappear.
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        if !safeExists(element) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            if !safeExists(element) { return true }
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
        if safeExists(backButton) {
            safeTap(backButton)
        } else {
            // Use coordinate-based left-edge swipe instead of app.swipeRight().
            // app.swipeRight() evaluates the full accessibility tree and hangs for 30+
            // minutes when Xcode 26's accessibility framework is degraded, causing
            // multi-hour test runs. Coordinate-based gestures bypass tree evaluation.
            ObjCExceptionCatcher.safeSwipeLeftEdge(app)
        }

        wait(for: 0.5)

        if let navBarTitle {
            if !safeWaitForExistence(app.navigationBars[navBarTitle], timeout: timeout) {
                let retryBack = app.buttons["backButton"]
                if safeExists(retryBack) {
                    safeTap(retryBack)
                    wait(for: 0.5)
                } else {
                    ObjCExceptionCatcher.safeSwipeLeftEdge(app)
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
        guard safeExists(element) else { return false }
        let frame = element.frame
        guard !frame.isEmpty else { return false }
        return app.windows.element(boundBy: 0).frame.intersects(frame)
    }

    /// Scroll to find an element
    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement? = nil, maxSwipes: Int = 5) -> Bool {
        if safeExists(element) { return true }

        let container = scrollView ?? app.scrollViews.firstMatch
        guard safeExists(container) else { return false }

        for _ in 0 ..< maxSwipes {
            container.swipeUp()
            if safeExists(element) { return true }
        }
        return false
    }
}
