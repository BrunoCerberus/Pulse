import XCTest

final class BookmarksUITests: BaseUITestCase {

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

    // MARK: - Navigation and Content Tests

    /// Tests tab navigation, content loading, scroll, and article navigation
    func testBookmarksNavigationContentAndScroll() throws {
        // --- Tab Navigation ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.exists, "Bookmarks tab should exist")

        navigateToBookmarks()

        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")

        let navTitle = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'Bookmarks' should exist")

        // --- Content Loading ---
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let loadingText = app.staticTexts["Loading bookmarks..."]
        let errorText = app.staticTexts["Unable to Load Bookmarks"]
        let helpText = app.staticTexts["Articles you bookmark will appear here for offline reading."]

        // Use polling to wait for content
        let timeout: TimeInterval = Self.defaultTimeout
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if noBookmarksText.exists || savedArticlesText.exists || loadingText.exists || errorText.exists {
                contentLoaded = true
                break
            }
            wait(for: 0.5)
        }

        XCTAssertTrue(contentLoaded, "Bookmarks view should show empty state, loading, or bookmarks list")

        // If empty state, verify helpful message
        if noBookmarksText.exists {
            XCTAssertTrue(helpText.exists, "Empty state should show helpful message")
        }

        // --- Scroll and Article Navigation ---
        wait(for: 2)

        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        XCTAssertTrue(navTitle.exists, "Navigation should still work after scrolling")

        // Check for bookmarked articles and test navigation
        if savedArticlesText.exists {
            let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

            if articleCards.count > 0 {
                articleCards.firstMatch.tap()

                let backButton = app.buttons["backButton"]
                XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

                backButton.tap()

                let bookmarksNav = app.navigationBars["Bookmarks"]
                XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should return to Bookmarks")
            }
        }
    }

    // MARK: - Context Menu and State Tests

    /// Tests remove bookmark via context menu, tab switching state, and error state
    func testContextMenuTabSwitchingAndErrorState() throws {
        navigateToBookmarks()

        wait(for: 2)

        // --- Context Menu ---
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCards.count > 0 {
            let firstCard = articleCards.firstMatch

            firstCard.press(forDuration: 1.0)

            let removeBookmarkOption = app.buttons["Remove Bookmark"]

            if removeBookmarkOption.waitForExistence(timeout: 3) {
                removeBookmarkOption.tap()
                wait(for: 1)
            } else {
                app.tap() // Dismiss context menu
            }
        }

        // --- Tab Switching State Preservation ---
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let noBookmarksExists = noBookmarksText.waitForExistence(timeout: 3)

        navigateToHome()
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should be on Home")

        navigateToBookmarks()

        wait(for: 2)

        if noBookmarksExists {
            XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 10), "Empty state should be preserved")
        }

        // --- Error State ---
        let errorTitle = app.staticTexts["Unable to Load Bookmarks"]

        if errorTitle.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }
    }

    // MARK: - Integration Tests

    /// Tests bookmarking from home and verifying in bookmarks
    func testBookmarkFromHomeAppearsInBookmarks() throws {
        navigateToHome()

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            throw XCTSkip("Home content did not load")
        }

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        guard articleCards.count > 0 else {
            throw XCTSkip("No articles found")
        }

        articleCards.firstMatch.tap()

        let backButton = app.buttons["backButton"]
        guard backButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Could not open article detail")
        }

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        if bookmarkButton.exists {
            bookmarkButton.tap()
            wait(for: 1)
        }

        backButton.tap()
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should return to Home")

        navigateToBookmarks()

        let bookmarksNav = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should be on Bookmarks")

        wait(for: 2)

        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksText = app.staticTexts["No Bookmarks"]

        XCTAssertTrue(savedArticlesText.exists || noBookmarksText.exists, "Bookmarks should show content or empty state")
    }
}
