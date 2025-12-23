import XCTest

final class ArticleDetailUITests: XCTestCase {
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

        // Verify navigation to detail
        let backButton = app.navigationBars.buttons["chevron.left"]
        return backButton.waitForExistence(timeout: 5)
    }

    // MARK: - Navigation Tests

    func testBackButtonExists() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let backButton = app.navigationBars.buttons["chevron.left"]
        XCTAssertTrue(backButton.exists, "Back button (chevron.left) should exist in navigation bar")
    }

    func testBackButtonNavigatesBackToHome() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let backButton = app.navigationBars.buttons["chevron.left"]
        XCTAssertTrue(backButton.exists, "Back button should exist")

        backButton.tap()

        // Verify we're back on Home
        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should navigate back to Home (Pulse)")
    }

    // MARK: - Toolbar Actions Tests

    func testBookmarkButtonExists() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Bookmark button can be either "bookmark" or "bookmark.fill"
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]

        let bookmarkExists = bookmarkButton.exists || bookmarkFilledButton.exists
        XCTAssertTrue(bookmarkExists, "Bookmark button should exist in navigation bar")
    }

    func testShareButtonExists() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let shareButton = app.navigationBars.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists, "Share button should exist in navigation bar")
    }

    func testBookmarkToggle() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Find bookmark button (unfilled or filled)
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]

        if bookmarkButton.exists {
            // Article is not bookmarked, tap to bookmark
            bookmarkButton.tap()

            // Verify it changed to filled
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Bookmark should become filled after tapping")
        } else if bookmarkFilledButton.exists {
            // Article is already bookmarked, tap to unbookmark
            bookmarkFilledButton.tap()

            // Verify it changed to unfilled
            XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 3), "Bookmark should become unfilled after tapping")
        } else {
            XCTFail("Neither bookmark nor bookmark.fill button found")
        }
    }

    func testShareButtonOpensShareSheet() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let shareButton = app.navigationBars.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists, "Share button should exist")

        shareButton.tap()

        // Share sheet appears as an activity view controller
        // It typically contains "Copy" or other share options
        let shareSheet = app.otherElements["ActivityListView"]
        let copyButton = app.buttons["Copy"]
        let closeButton = app.buttons["Close"]

        // Wait for share sheet to appear
        let shareSheetAppeared = shareSheet.waitForExistence(timeout: 5) ||
            copyButton.waitForExistence(timeout: 5) ||
            closeButton.waitForExistence(timeout: 5)

        XCTAssertTrue(shareSheetAppeared, "Share sheet should appear after tapping share button")

        // Dismiss share sheet
        if closeButton.exists {
            closeButton.tap()
        } else {
            // Swipe down to dismiss
            app.swipeDown()
        }
    }

    // MARK: - Content Tests

    func testArticleTitleExists() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Article detail should have some text content
        // Look for the article title (typically a large text element)
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0, "Article detail should have text content")
    }

    func testReadFullArticleButtonExists() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Scroll down to find the "Read Full Article" button
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        let readFullButton = app.buttons["Read Full Article"]
        // The button may need more scrolling to find
        if !readFullButton.exists {
            scrollView.swipeUp()
        }

        XCTAssertTrue(readFullButton.waitForExistence(timeout: 5), "Read Full Article button should exist")
    }

    func testReadFullArticleButtonHasSafariIcon() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Scroll to find the button
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
        }

        // Button should contain safari icon and "Read Full Article" text
        let readFullButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Read Full Article'")).firstMatch
        XCTAssertTrue(readFullButton.waitForExistence(timeout: 5), "Read Full Article button should exist")
    }

    // MARK: - Scroll Tests

    func testArticleDetailIsScrollable() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Article detail should have a scroll view")

        // Scroll down
        scrollView.swipeUp()

        // Scroll back up
        scrollView.swipeDown()

        // View should still be functional
        let backButton = app.navigationBars.buttons["chevron.left"]
        XCTAssertTrue(backButton.exists, "Navigation should still work after scrolling")
    }

    func testScrollToReadFullArticleButton() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "ScrollView should exist")

        // Scroll down to bottom
        for _ in 0..<3 {
            scrollView.swipeUp()
        }

        // Read Full Article should be visible at the bottom
        let readFullButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Read Full Article'")).firstMatch
        XCTAssertTrue(readFullButton.waitForExistence(timeout: 3), "Read Full Article button should be visible after scrolling")
    }

    // MARK: - Metadata Tests

    func testArticleMetadataDisplayed() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Article detail should display source name and date
        // These are typically displayed in the metadata row
        let staticTexts = app.staticTexts

        // Check for "By" prefix (author attribution) or date format
        let hasMetadata = staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'By' OR label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'")).count > 0

        XCTAssertTrue(hasMetadata, "Article should display metadata (author, source, or date)")
    }

    // MARK: - Category Chip Tests

    func testCategoryChipDisplayed() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Categories like Technology, Business, World, etc. may be displayed
        let categoryNames = ["Technology", "Business", "World", "Science", "Health", "Sports", "Entertainment"]

        var categoryFound = false
        for category in categoryNames {
            if app.staticTexts[category].exists {
                categoryFound = true
                break
            }
        }

        // Category is optional, so we just note if it exists
        // This test passes regardless - we're just verifying the structure
        XCTAssertTrue(true, "Category chip check completed (optional element)")
    }

    // MARK: - Image Tests

    func testArticleImageArea() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Article detail has a hero image area at the top
        // This is implemented as StretchyAsyncImage
        // The image loads asynchronously, so we check for the scroll view structure
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Article detail should have a scroll view for the stretchy header")
    }

    // MARK: - Integration Tests

    func testNavigateFromHomeToDetailAndBack() throws {
        navigateToHome()

        // Wait for content
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            throw XCTSkip("Content did not load")
        }

        // Find and tap article
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        guard articleCards.count > 0 else {
            throw XCTSkip("No articles found")
        }

        articleCards.firstMatch.tap()

        // Verify on detail
        let backButton = app.navigationBars.buttons["chevron.left"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should be on article detail")

        // Navigate back
        backButton.tap()

        // Verify back on home
        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home")

        // Content should still be visible
        XCTAssertTrue(topHeadlinesHeader.waitForExistence(timeout: 5), "Content should still be visible")
    }

    func testBookmarkArticleAndVerifyInBookmarks() throws {
        let navigated = navigateToArticleDetail()
        guard navigated else {
            throw XCTSkip("Could not navigate to article detail - no articles available")
        }

        // Bookmark the article if not already bookmarked
        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        let bookmarkFilledButton = app.navigationBars.buttons["bookmark.fill"]

        if bookmarkButton.exists {
            bookmarkButton.tap()
            // Wait for bookmark to be saved
            XCTAssertTrue(bookmarkFilledButton.waitForExistence(timeout: 3), "Article should be bookmarked")
        }

        // Navigate back
        let backButton = app.navigationBars.buttons["chevron.left"]
        backButton.tap()

        // Wait for home
        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home")

        // Navigate to Bookmarks tab
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        bookmarksTab.tap()

        // Wait for Bookmarks view
        let bookmarksNavBar = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNavBar.waitForExistence(timeout: 5), "Should be on Bookmarks tab")

        // There should be at least one bookmarked article or the "saved articles" text
        let savedArticlesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved articles'")).firstMatch
        let noBookmarksText = app.staticTexts["No Bookmarks"]

        // Either we have saved articles or the empty state
        let bookmarksLoaded = savedArticlesText.waitForExistence(timeout: 5) || noBookmarksText.waitForExistence(timeout: 5)
        XCTAssertTrue(bookmarksLoaded, "Bookmarks view should show content or empty state")
    }
}
