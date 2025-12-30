import XCTest

final class ArticleDetailUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Navigate to Home tab
    private func navigateToHome() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        }
    }

    /// Navigate to an article detail by tapping the first available article
    /// - Returns: True if successfully navigated to article detail
    @discardableResult
    private func navigateToArticleDetail() -> Bool {
        navigateToHome()

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

        wait(for: 2)

        let backButtonAfterShare = app.buttons["backButton"]
        XCTAssertTrue(backButtonAfterShare.waitForExistence(timeout: 10), "Back button should exist after share sheet dismissed")

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

        scrollViewGeneric.swipeDown()

        XCTAssertTrue(backButtonAfterShare.exists, "Navigation should still work after scrolling")

        // --- Back Navigation ---
        var isHittable = false
        for _ in 0..<10 {
            if backButtonAfterShare.exists && backButtonAfterShare.isHittable {
                isHittable = true
                break
            }
            wait(for: 0.5)
        }
        XCTAssertTrue(isHittable, "Back button should be tappable")
        backButtonAfterShare.tap()

        let homeNavBar = app.navigationBars["Pulse"]
        let homeTab = app.tabBars.buttons["Home"]
        let navigatedBack = homeNavBar.waitForExistence(timeout: 10) || (homeTab.exists && homeTab.isSelected)
        XCTAssertTrue(navigatedBack, "Should navigate back to Home")

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        XCTAssertTrue(topHeadlinesHeader.waitForExistence(timeout: 5) || homeNavBar.exists, "Home content should be visible")

        // --- Bookmarks Verification ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        bookmarksTab.tap()

        let bookmarksNavBar = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNavBar.waitForExistence(timeout: 5), "Should be on Bookmarks tab")

        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksText = app.staticTexts["No Bookmarks"]

        let bookmarksLoaded = savedArticlesText.waitForExistence(timeout: 5) || noBookmarksText.waitForExistence(timeout: 5)
        XCTAssertTrue(bookmarksLoaded, "Bookmarks view should show content or empty state")
    }
}
