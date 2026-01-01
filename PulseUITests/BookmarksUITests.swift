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

    // MARK: - Combined Flow Test

    /// Tests bookmarks navigation, content, context menu, and bookmark persistence
    func testBookmarksFlow() throws {
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

        // --- Context Menu and State Preservation ---
        wait(for: 2)

        let articleCardsForMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCardsForMenu.count > 0 {
            let firstCard = articleCardsForMenu.firstMatch

            firstCard.press(forDuration: 1.0)

            let removeBookmarkOption = app.buttons["Remove Bookmark"]

            if removeBookmarkOption.waitForExistence(timeout: 3) {
                removeBookmarkOption.tap()
                wait(for: 1)
            } else {
                app.tap()
            }
        }

        let noBookmarksExists = noBookmarksText.waitForExistence(timeout: 3)

        navigateToHome()
        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should be on Home")

        navigateToBookmarks()

        wait(for: 2)

        if noBookmarksExists {
            XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 10), "Empty state should be preserved")
        }

        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }

        // --- Bookmark From Home ---
        navigateToHome()

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        if topHeadlinesHeader.waitForExistence(timeout: 10) {
            let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
            if articleCards.count > 0 {
                articleCards.firstMatch.tap()

                let backButton = app.buttons["backButton"]
                if backButton.waitForExistence(timeout: 5) {
                    let bookmarkButton = app.navigationBars.buttons["bookmark"]
                    if bookmarkButton.exists {
                        bookmarkButton.tap()
                        wait(for: 1)
                    }

                    backButton.tap()
                }
            }
        } else {
            let errorState = app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists
            XCTAssertTrue(errorState, "Home should show an empty or error state when articles are unavailable")
        }

        let homeNavAfterBookmark = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavAfterBookmark.waitForExistence(timeout: 5), "Should return to Home")

        navigateToBookmarks()

        let bookmarksNav = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should be on Bookmarks")

        wait(for: 2)

        let savedArticlesTextAfter = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksTextAfter = app.staticTexts["No Bookmarks"]

        XCTAssertTrue(savedArticlesTextAfter.exists || noBookmarksTextAfter.exists, "Bookmarks should show content or empty state")
    }
}
