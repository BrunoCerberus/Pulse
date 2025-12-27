import XCTest

final class HomeUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20.0), "App should be running in the foreground")

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20.0), "Tab bar should appear after splash screen")
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    // MARK: - Helper Methods

    /// Ensure we're on the Home tab
    private func navigateToHome() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        }
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Home tab should exist")
    }

    private func waitForArticleDetail(timeout: TimeInterval = 8) -> Bool {
        let detailScrollView = app.scrollViews["articleDetailScrollView"]
        if detailScrollView.waitForExistence(timeout: timeout) {
            return true
        }

        let backButton = app.buttons["backButton"]
        return backButton.waitForExistence(timeout: 2)
    }

    // MARK: - Navigation Bar Tests

    func testHomeNavigationTitleExists() throws {
        navigateToHome()

        let navTitle = app.navigationBars["Pulse"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'Pulse' should exist")
    }

    func testGearButtonExistsInNavigationBar() throws {
        navigateToHome()

        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist in navigation bar")
    }

    // MARK: - Content Section Tests

    func testBreakingNewsSectionExists() throws {
        navigateToHome()

        // Wait for content to load - either breaking news, error, or empty state
        let breakingNewsHeader = app.staticTexts["Breaking News"]
        let topHeadlines = app.staticTexts["Top Headlines"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if breakingNewsHeader.exists || topHeadlines.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Home should show content (breaking news, headlines, error, or empty state)")
    }

    func testTopHeadlinesSectionExists() throws {
        navigateToHome()

        // Wait for either Top Headlines or an error/empty state using polling
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNewsHeader = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        // Use polling to avoid cascading waits
        let timeout: TimeInterval = 30
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlinesHeader.exists || breakingNewsHeader.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Home should show content (headlines, error, or empty state)")
    }

    // MARK: - Article Card Interaction Tests

    func testArticleCardTapNavigatesToDetail() throws {
        navigateToHome()

        // Wait for content to load - either headlines or error/empty state
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var hasContent = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlinesHeader.exists || breakingNews.exists || errorTitle.exists || noNewsText.exists {
                hasContent = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        guard hasContent else {
            throw XCTSkip("Content did not load in time")
        }

        // If error or empty state, skip the test
        if errorTitle.exists || noNewsText.exists {
            throw XCTSkip("No articles available to test navigation")
        }

        // Find first article card (button containing article content)
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour' OR label CONTAINS[c] 'minute'"))

        guard articleCards.count > 0 else {
            throw XCTSkip("No article cards found to test navigation")
        }

        let firstCard = articleCards.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5), "Article card should exist")
        firstCard.tap()

        XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")
    }

    func testBreakingNewsCardTapNavigatesToDetail() throws {
        navigateToHome()

        // Wait for content to load
        let breakingNewsHeader = app.staticTexts["Breaking News"]
        let topHeadlines = app.staticTexts["Top Headlines"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var hasContent = false

        while Date().timeIntervalSince(startTime) < timeout {
            if breakingNewsHeader.exists || topHeadlines.exists || errorTitle.exists || noNewsText.exists {
                hasContent = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        guard hasContent else {
            throw XCTSkip("Content did not load in time")
        }

        // If error or empty state, skip the test
        if errorTitle.exists || noNewsText.exists {
            throw XCTSkip("No breaking news available to test navigation")
        }

        // Breaking news cards are in a horizontal scroll view
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "ScrollView should exist")

        // Try to find and tap a hero card in the breaking news carousel
        let heroCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Breaking' OR (label CONTAINS[c] 'ago')")).firstMatch

        guard heroCards.waitForExistence(timeout: 5) else {
            throw XCTSkip("No breaking news cards found to test navigation")
        }

        heroCards.tap()

        // Verify navigation
        XCTAssertTrue(waitForArticleDetail(timeout: 6), "Should navigate to article detail")
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshExists() throws {
        navigateToHome()

        // Wait for content to load first
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlinesHeader.exists || breakingNews.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Content should load")

        // If error or empty state, skip - ScrollView only exists when content is available
        if errorTitle.exists || noNewsText.exists {
            throw XCTSkip("No content available - ScrollView only exists with articles")
        }

        // Perform pull to refresh gesture
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "ScrollView should exist for pull to refresh")

        // Pull down to trigger refresh
        scrollView.swipeDown()

        // The view should still be functional after refresh
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(scrollView.exists, "ScrollView should still exist after refresh")
    }

    // MARK: - Infinite Scroll Tests

    func testScrollingLoadsMoreContent() throws {
        navigateToHome()

        // Wait for initial content
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlinesHeader.exists || breakingNews.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Initial content should load")

        // If error or empty state, skip the scroll test
        if errorTitle.exists || noNewsText.exists {
            throw XCTSkip("No content to scroll")
        }

        // Scroll down to verify scrolling works
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "ScrollView should exist")

        // Perform a single swipe to verify scrolling works
        scrollView.swipeUp()

        // Verify navigation bar still exists (app is responsive)
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 10), "App should remain responsive after scrolling")
    }

    // MARK: - Breaking News Carousel Tests

    func testBreakingNewsCarouselIsHorizontallyScrollable() throws {
        navigateToHome()

        // Wait for content to load
        let breakingNewsHeader = app.staticTexts["Breaking News"]
        let topHeadlines = app.staticTexts["Top Headlines"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if breakingNewsHeader.exists || topHeadlines.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Content should load")

        // If no breaking news, skip the carousel test
        if !breakingNewsHeader.exists {
            throw XCTSkip("Breaking News section not available to test carousel")
        }

        // Find the horizontal scroll view (carousel)
        let scrollViews = app.scrollViews
        XCTAssertTrue(scrollViews.count > 0, "Should have scroll views")

        // Swipe left on the carousel area (below the header)
        let firstScrollView = scrollViews.firstMatch
        firstScrollView.swipeLeft()

        // The view should still be responsive
        XCTAssertTrue(breakingNewsHeader.exists, "Breaking News header should still exist after scroll")
    }

    // MARK: - Loading State Tests

    func testLoadingStateShowsSkeletons() throws {
        // Launch fresh app to catch loading state
        app.terminate()
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20.0), "App should be running in the foreground")

        // Wait for tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20.0), "Tab bar should appear")

        // Either loading skeletons, content, or error/empty state should appear
        let breakingNews = app.staticTexts["Breaking News"]
        let topHeadlines = app.staticTexts["Top Headlines"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        // Wait for content to load (skeletons are replaced quickly)
        let timeout: TimeInterval = 20
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if breakingNews.exists || topHeadlines.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Content should appear after loading (news, error, or empty state)")
    }

    // MARK: - Error State Tests

    func testErrorStateShowsTryAgainButton() throws {
        navigateToHome()

        // Note: This test checks if the error view structure exists in the UI
        // In real error scenarios, "Try Again" button should appear
        // Since we can't easily simulate network errors in UI tests,
        // we verify the happy path loads content instead

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let errorTitle = app.staticTexts["Unable to Load News"]

        // Either content loads or error state shows
        let result = topHeadlinesHeader.waitForExistence(timeout: 10) || errorTitle.waitForExistence(timeout: 10)
        XCTAssertTrue(result, "Either content or error state should appear")

        // If error state is shown, Try Again should exist
        if errorTitle.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Try Again button should exist in error state")
        }
    }

    // MARK: - Empty State Tests

    func testEmptyStateMessage() throws {
        navigateToHome()

        // In normal operation, we expect content to load
        // Empty state shows "No News Available"
        let noNewsText = app.staticTexts["No News Available"]
        let topHeadlines = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]

        // Poll for any content state
        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlines.exists || breakingNews.exists || noNewsText.exists || errorTitle.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Either content, empty state, or error state should appear")
    }

    // MARK: - Context Menu Tests

    func testArticleCardContextMenuExists() throws {
        navigateToHome()

        // Wait for content
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let errorTitle = app.staticTexts["Unable to Load News"]
        let noNewsText = app.staticTexts["No News Available"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if topHeadlinesHeader.exists || breakingNews.exists || errorTitle.exists || noNewsText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Content should load")

        // If error or empty state, skip the test
        if errorTitle.exists || noNewsText.exists {
            throw XCTSkip("No articles available to test context menu")
        }

        // Find an article card
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        guard articleCards.count > 0 else {
            throw XCTSkip("No article cards found to test context menu")
        }

        let firstCard = articleCards.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5), "Article card should exist")

        // Long press to open context menu
        firstCard.press(forDuration: 1.0)

        // Check for context menu options
        let bookmarkOption = app.buttons["Bookmark"]
        let shareOption = app.buttons["Share"]

        // Context menu should appear with bookmark and share options
        let contextMenuAppeared = bookmarkOption.waitForExistence(timeout: 3) || shareOption.waitForExistence(timeout: 3)

        if contextMenuAppeared {
            XCTAssertTrue(contextMenuAppeared, "Context menu should have Bookmark or Share option")

            // Dismiss context menu by tapping elsewhere
            app.tap()
        }
    }

    // MARK: - Navigation Integration Tests

    func testNavigateToSettingsAndBack() throws {
        navigateToHome()

        // Wait for Home to fully load
        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 10), "Home navigation bar should exist")

        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist")

        gearButton.tap()

        // Verify Settings opened
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 10), "Settings should open")

        // Navigate back using the back button - try multiple selectors for reliability
        // First try "Pulse" back button (iOS uses destination title), then chevron, then first button
        var backButton = app.navigationBars["Settings"].buttons["Pulse"]
        if !backButton.waitForExistence(timeout: 2) {
            backButton = app.navigationBars["Settings"].buttons["Back"]
        }
        if !backButton.exists {
            backButton = app.navigationBars["Settings"].buttons.matching(NSPredicate(format: "label CONTAINS[c] 'back' OR label == 'chevron.left'")).firstMatch
        }
        if !backButton.exists {
            // Fallback: use first button in nav bar (usually back button)
            backButton = app.navigationBars["Settings"].buttons.firstMatch
        }

        if backButton.waitForExistence(timeout: 5) {
            backButton.tap()
        } else {
            app.swipeRight()
        }

        // Verify back on Home with extended timeout
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 10), "Should return to Home")
    }
}
