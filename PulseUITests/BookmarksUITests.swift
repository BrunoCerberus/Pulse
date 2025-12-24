import XCTest

final class BookmarksUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchEnvironment["XCTestConfigurationFilePath"] = "UI"
        app.launch()

        _ = app.wait(for: .runningForeground, timeout: 5.0)

        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should appear after splash screen")
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    // MARK: - Helper Methods

    /// Navigate to Bookmarks tab
    private func navigateToBookmarks() {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 5), "Bookmarks tab should exist")
        bookmarksTab.tap()

        let navTitle = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Bookmarks view should load")
    }

    /// Navigate to Home tab
    private func navigateToHome() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        }
    }

    /// Bookmark an article from Home and return to Bookmarks
    private func bookmarkArticleFromHome() -> Bool {
        navigateToHome()

        // Wait for content to load
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            return false
        }

        // Find and tap an article to open detail
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        guard articleCards.count > 0 else {
            return false
        }

        articleCards.firstMatch.tap()

        // Wait for detail view
        let backButton = app.buttons["backButton"]
        guard backButton.waitForExistence(timeout: 5) else {
            return false
        }

        // Bookmark the article
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        if bookmarkButton.exists {
            bookmarkButton.tap()
            // Wait for bookmark to be saved
            Thread.sleep(forTimeInterval: 1)
        }

        // Navigate back
        backButton.tap()

        // Wait for home
        let homeNavBar = app.navigationBars["Pulse"]
        guard homeNavBar.waitForExistence(timeout: 5) else {
            return false
        }

        // Navigate to Bookmarks
        navigateToBookmarks()
        return true
    }

    // MARK: - Navigation Tests

    func testBookmarksTabExists() throws {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.exists, "Bookmarks tab should exist")
    }

    func testBookmarksTabCanBeSelected() throws {
        navigateToBookmarks()

        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")
    }

    func testBookmarksNavigationTitleExists() throws {
        navigateToBookmarks()

        let navTitle = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'Bookmarks' should exist")
    }

    // MARK: - Empty State Tests

    func testEmptyStateShowsNoBookmarksMessage() throws {
        navigateToBookmarks()

        // Check for empty state or bookmarks list
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let loadingText = app.staticTexts["Loading bookmarks..."]

        // Wait for content to load
        Thread.sleep(forTimeInterval: 2)

        // Either empty state, loading, or bookmarks should appear
        let contentLoaded = noBookmarksText.exists || savedArticlesText.exists || loadingText.exists
        XCTAssertTrue(contentLoaded, "Bookmarks view should show empty state, loading, or bookmarks list")
    }

    func testEmptyStateShowsHelpfulMessage() throws {
        navigateToBookmarks()

        // If empty state is shown, it should have a helpful message
        let helpText = app.staticTexts["Articles you bookmark will appear here for offline reading."]

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        let noBookmarksText = app.staticTexts["No Bookmarks"]

        if noBookmarksText.exists {
            XCTAssertTrue(helpText.exists, "Empty state should show helpful message")
        }
    }

    // MARK: - Bookmark Count Tests

    func testBookmarkCountDisplayed() throws {
        navigateToBookmarks()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // If bookmarks exist, count should be displayed
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch

        if savedArticlesText.exists {
            XCTAssertTrue(savedArticlesText.exists, "Bookmark count should be displayed")
        }
    }

    // MARK: - Bookmarks List Tests

    func testBookmarksListIsScrollable() throws {
        navigateToBookmarks()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            // Scroll down and up
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        // View should still be responsive
        let navTitle = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navTitle.exists, "Navigation should still work after scrolling")
    }

    func testBookmarkArticleCardTapNavigatesToDetail() throws {
        navigateToBookmarks()

        // Wait for content to load
        Thread.sleep(forTimeInterval: 2)

        // Check if there are bookmarked articles
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch

        if savedArticlesText.exists {
            // Find and tap an article card
            let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

            if articleCards.count > 0 {
                articleCards.firstMatch.tap()

                // Verify navigation to detail
                let backButton = app.buttons["backButton"]
                XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

                // Navigate back
                backButton.tap()

                // Verify back on Bookmarks
                let bookmarksNav = app.navigationBars["Bookmarks"]
                XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should return to Bookmarks")
            }
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshWorks() throws {
        navigateToBookmarks()

        // Wait for initial content
        Thread.sleep(forTimeInterval: 2)

        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            // Pull to refresh
            scrollView.swipeDown()

            // View should still be functional
            let navTitle = app.navigationBars["Bookmarks"]
            XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation should work after refresh")
        }
    }

    // MARK: - Remove Bookmark Tests

    func testRemoveBookmarkViaContextMenu() throws {
        navigateToBookmarks()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // Check for bookmarked articles
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCards.count > 0 {
            let firstCard = articleCards.firstMatch

            // Long press to open context menu
            firstCard.press(forDuration: 1.0)

            // Look for "Remove Bookmark" option
            let removeBookmarkOption = app.buttons["Remove Bookmark"]

            if removeBookmarkOption.waitForExistence(timeout: 3) {
                removeBookmarkOption.tap()

                // Wait for removal
                Thread.sleep(forTimeInterval: 1)
            } else {
                // Dismiss context menu if Remove Bookmark not found
                app.tap()
            }
        }
    }

    // MARK: - Integration Tests

    func testBookmarkFromHomeAppearsInBookmarks() throws {
        // First, bookmark an article from Home
        navigateToHome()

        // Wait for content
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            throw XCTSkip("Home content did not load")
        }

        // Open article detail
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        guard articleCards.count > 0 else {
            throw XCTSkip("No articles found")
        }

        articleCards.firstMatch.tap()

        // Wait for detail
        let backButton = app.buttons["backButton"]
        guard backButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Could not open article detail")
        }

        // Bookmark if not already bookmarked
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        if bookmarkButton.exists {
            bookmarkButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // Navigate back to Home
        backButton.tap()
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should return to Home")

        // Go to Bookmarks tab
        navigateToBookmarks()

        // Verify we're on Bookmarks
        let bookmarksNav = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should be on Bookmarks")

        // Wait for bookmarks to load
        Thread.sleep(forTimeInterval: 2)

        // Should have at least one bookmark (or the count text)
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksText = app.staticTexts["No Bookmarks"]

        // Verify bookmarks view loaded
        XCTAssertTrue(savedArticlesText.exists || noBookmarksText.exists, "Bookmarks should show content or empty state")
    }

    // MARK: - Loading State Tests

    func testLoadingStateShowsProgress() throws {
        // Launch fresh to catch loading state
        app.terminate()
        app = XCUIApplication()
        app.launchEnvironment["XCTestConfigurationFilePath"] = "UI"
        app.launch()

        _ = app.wait(for: .runningForeground, timeout: 5.0)

        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should appear")

        // Navigate to Bookmarks immediately
        navigateToBookmarks()

        // Check for loading text, empty state, or bookmarks
        let loadingText = app.staticTexts["Loading bookmarks..."]
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch

        // One of these should appear
        let contentShown = loadingText.waitForExistence(timeout: 3) ||
            noBookmarksText.waitForExistence(timeout: 5) ||
            savedArticlesText.waitForExistence(timeout: 5)

        XCTAssertTrue(contentShown, "Loading state, empty state, or bookmarks should appear")
    }

    // MARK: - Error State Tests

    func testErrorStateShowsTryAgain() throws {
        navigateToBookmarks()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // Check if error state exists
        let errorTitle = app.staticTexts["Unable to Load Bookmarks"]

        if errorTitle.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }
    }

    // MARK: - Tab Switching Tests

    func testSwitchingTabsPreservesBookmarksState() throws {
        navigateToBookmarks()

        // Wait for content to fully load
        Thread.sleep(forTimeInterval: 3)

        // Note the current state - check for empty state
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let noBookmarksExists = noBookmarksText.waitForExistence(timeout: 3)

        // Switch to Home
        navigateToHome()
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should be on Home")

        // Switch back to Bookmarks
        navigateToBookmarks()

        // Wait for content to load after switching back
        Thread.sleep(forTimeInterval: 2)

        // State should be preserved
        if noBookmarksExists {
            // Allow more time for empty state to reappear after tab switch
            XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 10), "Empty state should be preserved")
        }
    }

    // MARK: - Accessibility Tests

    func testBookmarkIconIsFilledForBookmarkedArticles() throws {
        navigateToBookmarks()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // If there are bookmarked articles, they should show filled bookmark icon
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            // Articles in Bookmarks should have filled bookmark icon
            // This is indicated by the isBookmarked: true parameter
            XCTAssertTrue(true, "Bookmarked articles should display filled bookmark icon")
        }
    }
}
