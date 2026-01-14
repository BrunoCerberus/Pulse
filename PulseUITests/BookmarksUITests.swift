import XCTest

final class BookmarksUITests: BaseUITestCase {

    // MARK: - Combined Flow Test

    /// Tests bookmarks navigation, content, context menu, and bookmark persistence
    func testBookmarksFlow() throws {
        // --- Tab Navigation ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: Self.shortTimeout), "Bookmarks tab should exist")

        navigateToBookmarksTab()

        // Wait for nav bar to confirm we're on Bookmarks (more reliable than isSelected)
        let navTitle = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Bookmarks' should exist")

        // Verify tab is selected after navigation is confirmed
        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")

        // --- Content Loading ---
        let noBookmarksText = app.staticTexts["No Bookmarks"]
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let loadingText = app.staticTexts["Loading bookmarks..."]
        let errorText = app.staticTexts["Unable to Load Bookmarks"]
        let helpText = app.staticTexts["Articles you bookmark will appear here for offline reading."]

        let contentLoaded = waitForAny([noBookmarksText, savedArticlesText, loadingText, errorText], timeout: Self.defaultTimeout)

        XCTAssertTrue(contentLoaded, "Bookmarks view should show empty state, loading, or bookmarks list")

        if noBookmarksText.exists {
            XCTAssertTrue(helpText.exists, "Empty state should show helpful message")
        }

        // --- Scroll and Article Navigation ---
        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        XCTAssertTrue(navTitle.exists, "Navigation should still work after scrolling")

        if savedArticlesText.exists {
            let cards = articleCards()

            if cards.count > 0 {
                cards.firstMatch.tap()

                let backButton = app.buttons["backButton"]
                XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

                backButton.tap()

                let bookmarksNav = app.navigationBars["Bookmarks"]
                XCTAssertTrue(bookmarksNav.waitForExistence(timeout: 5), "Should return to Bookmarks")
            }
        }

        // --- Context Menu and State Preservation ---
        let articleCardsForMenu = articleCards()

        if articleCardsForMenu.count > 0 {
            let firstCard = articleCardsForMenu.firstMatch

            firstCard.press(forDuration: 0.5)

            let removeBookmarkOption = app.buttons["Remove Bookmark"]

            if removeBookmarkOption.waitForExistence(timeout: 3) {
                removeBookmarkOption.tap()
            } else {
                app.tap()
            }
        }

        let noBookmarksExists = noBookmarksText.waitForExistence(timeout: 2)

        navigateToTab("Home")
        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.shortTimeout), "Should be on Home")

        navigateToBookmarksTab()

        if noBookmarksExists {
            XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 10), "Empty state should be preserved")
        }

        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }

        // --- Bookmark From Home ---
        navigateToTab("Home")

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        if topHeadlinesHeader.waitForExistence(timeout: 10) {
            let homeArticleCards = articleCards()
            if homeArticleCards.count > 0 {
                homeArticleCards.firstMatch.tap()

                let backButton = app.buttons["backButton"]
                if backButton.waitForExistence(timeout: 5) {
                    let bookmarkButton = app.navigationBars.buttons["bookmark"]
                    if bookmarkButton.exists {
                        bookmarkButton.tap()
                    }

                    backButton.tap()
                }
            }
        } else {
            let errorState = app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists
            XCTAssertTrue(errorState, "Home should show an empty or error state when articles are unavailable")
        }

        let homeNavAfterBookmark = app.navigationBars["News"]
        XCTAssertTrue(homeNavAfterBookmark.waitForExistence(timeout: Self.shortTimeout), "Should return to Home")

        navigateToBookmarksTab()

        let bookmarksNav = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNav.waitForExistence(timeout: Self.shortTimeout), "Should be on Bookmarks")

        let savedArticlesTextAfter = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksTextAfter = app.staticTexts["No Bookmarks"]
        let loadingTextAfter = app.staticTexts["Loading bookmarks..."]

        // Use longer timeout after navigation flow - CI can be slower after multiple tab switches
        let finalStateLoaded = waitForAny([savedArticlesTextAfter, noBookmarksTextAfter, loadingTextAfter], timeout: 10)
        XCTAssertTrue(finalStateLoaded, "Bookmarks should show content, empty state, or loading state")
    }
}
