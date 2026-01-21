import XCTest

final class ArticleDetailUITests: BaseUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()

        // Speed optimizations
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"

        // Enable premium access for testing bookmark and other premium features
        app.launchEnvironment["MOCK_PREMIUM"] = "1"

        // Launch arguments to speed up tests
        app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
        app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]

        app.launch()

        // Launch verification
        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)
        wait(for: 0.3)

        // Wait for app to be ready - use same comprehensive detection as BaseUITestCase
        let tabBar = app.tabBars.firstMatch
        let homeTabButton = app.tabBars.buttons["Home"]
        let signInApple = app.buttons["Sign in with Apple"]
        let signInGoogle = app.buttons["Sign in with Google"]
        let loadingIndicator = app.activityIndicators.firstMatch

        // First, wait for the loading state to clear
        if loadingIndicator.waitForExistence(timeout: 2) {
            _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout)
        }

        // Now wait for either tab bar or sign-in to appear with multiple strategies
        var appReady = waitForAny([tabBar, homeTabButton, signInApple, signInGoogle], timeout: Self.launchTimeout)
        var foundTabBar = tabBar.exists || homeTabButton.exists

        // Fallback: try finding tab buttons directly if primary check fails
        if !appReady {
            let tabButtonNames = ["Home", "For You", "Feed", "Bookmarks", "Search"]
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
            // Debug info for diagnosing CI failures
            let hasActivityIndicator = app.activityIndicators.count > 0
            let hasButtons = app.buttons.count > 0
            let hasStaticTexts = app.staticTexts.count > 0
            let allButtonLabels = app.buttons.allElementsBoundByIndex.prefix(10).map { $0.label }
            XCTFail("App did not reach ready state - Debug: hasActivityIndicator=\(hasActivityIndicator), " +
                    "buttons=\(hasButtons), texts=\(hasStaticTexts), buttonLabels=\(allButtonLabels)")
            return
        }

        if foundTabBar {
            resetToHomeTab()
        }
    }

    // MARK: - Helper Methods

    /// Navigate to an article detail by tapping the first available article
    /// - Returns: True if successfully navigated to article detail
    @discardableResult
    private func navigateToArticleDetail() -> Bool {
        navigateToTab("Home")

        // Wait for articles to load
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            return false
        }

        // Find and tap first article card
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour' OR label CONTAINS[c] 'minute'"))

        guard articleCards.count > 0 else {
            return false
        }

        let firstCard = articleCards.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else {
            return false
        }

        firstCard.tap()

        return waitForArticleDetail()
    }

    // MARK: - Combined Flow Test

    /// Tests article detail toolbar, content, navigation, and bookmarking flow
    func testArticleDetailFlow() throws {
        let navigated = navigateToArticleDetail()
        if !navigated {
            let errorState = app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists
            XCTAssertTrue(errorState, "Home should show an empty or error state when article detail is unavailable")
            return
        }

        // --- Toolbar Buttons ---
        let backButton = app.buttons["backButton"]
        XCTAssertTrue(backButton.exists, "Back button should exist in navigation bar")

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]
        let bookmarkExists = bookmarkButton.exists || bookmarkFilledButton.exists
        XCTAssertTrue(bookmarkExists, "Bookmark button should exist in navigation bar")

        let shareButton = app.navigationBars.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists, "Share button should exist in navigation bar")

        // --- Bookmark Toggle ---
        if bookmarkButton.exists {
            bookmarkButton.tap()
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Bookmark should become filled after tapping")
        } else if bookmarkFilledButton.exists {
            bookmarkFilledButton.tap()
            XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 3), "Bookmark should become unfilled after tapping")
            bookmarkButton.tap()
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Bookmark should become filled after tapping again")
        }

        // --- Share Button ---
        shareButton.tap()

        let shareSheet = app.otherElements["ActivityListView"]
        let copyButton = app.buttons["Copy"]
        let closeButton = app.buttons["Close"]

        let shareSheetAppeared = shareSheet.waitForExistence(timeout: 5) ||
            copyButton.waitForExistence(timeout: 5) ||
            closeButton.waitForExistence(timeout: 5)

        XCTAssertTrue(shareSheetAppeared, "Share sheet should appear after tapping share button")

        if closeButton.exists {
            closeButton.tap()
        } else {
            app.swipeDown()
        }

        // Wait for share sheet to dismiss and back button to become available
        let backButtonAfterShare = app.buttons["backButton"]
        XCTAssertTrue(backButtonAfterShare.waitForExistence(timeout: 5), "Back button should exist after share sheet dismissed")

        // --- Article Content ---
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0, "Article detail should have text content")

        let hasMetadata = staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'By' OR label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'")).count > 0
        XCTAssertTrue(hasMetadata, "Article should display metadata (author, source, or date)")

        let scrollView = app.scrollViews["articleDetailScrollView"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Article detail should have a scroll view")

        let scrollViewGeneric = app.scrollViews.firstMatch
        XCTAssertTrue(scrollViewGeneric.exists, "Article detail should have a scroll view")

        for _ in 0 ..< 3 {
            scrollViewGeneric.swipeUp()
        }

        let readFullButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Read Full Article'")).firstMatch
        XCTAssertTrue(readFullButton.waitForExistence(timeout: 3), "Read Full Article button should be visible after scrolling")

        // Scroll to top by repeated swipe down gestures
        for _ in 0..<3 {
            scrollViewGeneric.swipeDown()
        }

        // Allow scroll to settle
        wait(for: 0.5)

        XCTAssertTrue(backButtonAfterShare.exists, "Navigation should still work after scrolling")

        // --- Back Navigation ---
        // Use predicate-based wait for hittability with longer timeout for scroll settling
        let hittablePredicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: hittablePredicate, object: backButtonAfterShare)
        let isHittable = XCTWaiter.wait(for: [expectation], timeout: 5) == .completed

        // If button isn't hittable, use swipe-right gesture to navigate back (enabled via .enableSwipeBack())
        if isHittable {
            backButtonAfterShare.tap()
        } else {
            // Use swipe gesture to go back - swipe from left edge
            app.swipeRight()
        }

        // Wait for navigation to complete
        wait(for: 1.0)

        let homeNavBar = app.navigationBars["News"]
        let homeTab = app.tabBars.buttons["Home"]

        // Check various indicators that we're back at home
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNewsHeader = app.staticTexts["Breaking News"]
        let homeTabSelected = homeTab.waitForExistence(timeout: 5) && homeTab.isSelected

        let navigatedBack = homeNavBar.waitForExistence(timeout: 10) ||
            homeTabSelected ||
            topHeadlinesHeader.waitForExistence(timeout: 3) ||
            breakingNewsHeader.waitForExistence(timeout: 3)

        XCTAssertTrue(navigatedBack, "Should navigate back to Home")

        // Bookmarking was already verified via bookmark button toggle earlier in the test
    }
}
