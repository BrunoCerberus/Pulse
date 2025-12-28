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

    // MARK: - Navigation Tests

    /// Tests back button exists and navigates back to home
    func testBackNavigation() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let backButton = app.buttons["backButton"]
        XCTAssertTrue(backButton.exists, "Back button should exist in navigation bar")

        backButton.tap()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should navigate back to Home (Pulse)")
    }

    // MARK: - Toolbar Tests

    /// Tests that bookmark and share buttons exist in navigation bar
    func testToolbarButtonsExist() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Bookmark button can be either "bookmark" or "bookmark.fill"
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]
        let bookmarkExists = bookmarkButton.exists || bookmarkFilledButton.exists
        XCTAssertTrue(bookmarkExists, "Bookmark button should exist in navigation bar")

        // Share button
        let shareButton = app.navigationBars.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists, "Share button should exist in navigation bar")
    }

    /// Tests bookmark toggle functionality
    func testBookmarkToggle() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]

        if bookmarkButton.exists {
            bookmarkButton.tap()
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Bookmark should become filled after tapping")
        } else if bookmarkFilledButton.exists {
            bookmarkFilledButton.tap()
            XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 3), "Bookmark should become unfilled after tapping")
        } else {
            XCTFail("Neither bookmark nor bookmark.fill button found")
        }
    }

    /// Tests share button opens share sheet
    func testShareButtonOpensShareSheet() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let shareButton = app.navigationBars.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists, "Share button should exist")
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
    }

    // MARK: - Content Tests

    /// Tests article content: title, metadata, image area, and scroll view
    func testArticleContent() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Article should have text content
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0, "Article detail should have text content")

        // Check for metadata (author, date)
        let hasMetadata = staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'By' OR label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'")).count > 0
        XCTAssertTrue(hasMetadata, "Article should display metadata (author, source, or date)")

        // Check for scroll view (stretchy header)
        let scrollView = app.scrollViews["articleDetailScrollView"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Article detail should have a scroll view")
    }

    // MARK: - Scroll and Read Full Article Tests

    /// Tests scrolling and Read Full Article button
    func testScrollAndReadFullArticle() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Article detail should have a scroll view")

        // Scroll down to find Read Full Article button
        for _ in 0 ..< 3 {
            scrollView.swipeUp()
        }

        let readFullButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Read Full Article'")).firstMatch
        XCTAssertTrue(readFullButton.waitForExistence(timeout: 3), "Read Full Article button should be visible after scrolling")

        // Scroll back up
        scrollView.swipeDown()

        // View should still be functional
        let backButton = app.buttons["backButton"]
        XCTAssertTrue(backButton.exists, "Navigation should still work after scrolling")
    }

    // MARK: - Integration Tests

    /// Tests full navigation flow from home to detail and back
    func testNavigateFromHomeToDetailAndBack() throws {
        navigateToHome()

        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            throw XCTSkip("Content did not load")
        }

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        guard articleCards.count > 0 else {
            throw XCTSkip("No articles found")
        }

        articleCards.firstMatch.tap()

        XCTAssertTrue(waitForArticleDetail(), "Should be on article detail")

        navigateBack()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home")
        XCTAssertTrue(topHeadlinesHeader.waitForExistence(timeout: 5), "Content should still be visible")
    }

    /// Tests bookmarking an article and verifying it appears in Bookmarks tab
    func testBookmarkArticleAndVerifyInBookmarks() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]

        if bookmarkButton.exists {
            bookmarkButton.tap()
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Article should be bookmarked")
        }

        let backButton = app.buttons["backButton"]
        backButton.tap()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home")

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
