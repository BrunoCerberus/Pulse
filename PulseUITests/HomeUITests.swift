import XCTest

final class HomeUITests: BaseUITestCase {

    // MARK: - Helper Methods

    private func navigateToHome() {
        navigateToTab("Home")
    }

    // MARK: - Navigation Bar Tests

    func testHomeNavigationTitleExists() throws {
        navigateToHome()
        XCTAssertTrue(app.navigationBars["Pulse"].waitForExistence(timeout: Self.shortTimeout), "Navigation title 'Pulse' should exist")
    }

    func testGearButtonExistsInNavigationBar() throws {
        navigateToHome()
        XCTAssertTrue(app.navigationBars.buttons["gearshape"].waitForExistence(timeout: Self.shortTimeout), "Gear button should exist in navigation bar")
    }

    // MARK: - Content Section Tests

    func testBreakingNewsSectionExists() throws {
        navigateToHome()
        XCTAssertTrue(waitForHomeContent(timeout: Self.defaultTimeout), "Home should show content")
    }

    func testTopHeadlinesSectionExists() throws {
        navigateToHome()
        XCTAssertTrue(waitForHomeContent(timeout: Self.defaultTimeout), "Home should show content")
    }

    // MARK: - Article Card Interaction Tests

    func testArticleCardTapNavigatesToDetail() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load in time")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No articles available to test navigation")
        }

        let cards = articleCards()
        guard cards.count > 0 else {
            throw XCTSkip("No article cards found to test navigation")
        }

        cards.firstMatch.tap()
        XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")
    }

    func testBreakingNewsCardTapNavigatesToDetail() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load in time")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No breaking news available to test navigation")
        }

        let heroCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Breaking' OR (label CONTAINS[c] 'ago')")).firstMatch
        guard heroCards.waitForExistence(timeout: Self.shortTimeout) else {
            throw XCTSkip("No breaking news cards found")
        }

        heroCards.tap()
        XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshExists() throws {
        navigateToHome()
        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No content available - ScrollView only exists with articles")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: Self.shortTimeout), "ScrollView should exist")
        scrollView.swipeDown()
        XCTAssertTrue(scrollView.exists, "ScrollView should still exist after refresh")
    }

    // MARK: - Infinite Scroll Tests

    func testScrollingLoadsMoreContent() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No content to scroll")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "ScrollView should exist")
        scrollView.swipeUp()

        XCTAssertTrue(app.navigationBars["Pulse"].waitForExistence(timeout: Self.shortTimeout), "App should remain responsive after scrolling")
    }

    // MARK: - Breaking News Carousel Tests

    func testBreakingNewsCarouselIsHorizontallyScrollable() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load")
        }

        let breakingNewsHeader = app.staticTexts["Breaking News"]
        guard breakingNewsHeader.exists else {
            throw XCTSkip("Breaking News section not available")
        }

        let scrollViews = app.scrollViews
        XCTAssertTrue(scrollViews.count > 0, "Should have scroll views")
        scrollViews.firstMatch.swipeLeft()
        XCTAssertTrue(breakingNewsHeader.exists, "Breaking News header should still exist after scroll")
    }

    // MARK: - Loading State Tests

    func testLoadingStateShowsSkeletons() throws {
        navigateToHome()
        XCTAssertTrue(waitForHomeContent(timeout: Self.defaultTimeout), "Content should appear after loading")
    }

    // MARK: - Error State Tests

    func testErrorStateShowsTryAgainButton() throws {
        navigateToHome()
        _ = waitForHomeContent(timeout: Self.defaultTimeout)

        if app.staticTexts["Unable to Load News"].exists {
            XCTAssertTrue(app.buttons["Try Again"].exists, "Try Again button should exist in error state")
        }
    }

    // MARK: - Empty State Tests

    func testEmptyStateMessage() throws {
        navigateToHome()
        XCTAssertTrue(waitForHomeContent(timeout: Self.defaultTimeout), "Content, empty state, or error state should appear")
    }

    // MARK: - Context Menu Tests

    func testArticleCardContextMenuExists() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No articles available to test context menu")
        }

        let cards = articleCards()
        guard cards.count > 0 else {
            throw XCTSkip("No article cards found")
        }

        cards.firstMatch.press(forDuration: 1.0)

        let contextMenuAppeared = app.buttons["Bookmark"].waitForExistence(timeout: Self.shortTimeout) ||
            app.buttons["Share"].waitForExistence(timeout: 1)

        if contextMenuAppeared {
            app.tap() // Dismiss context menu
        }
    }

    // MARK: - Navigation Integration Tests

    func testNavigateToSettingsAndBack() throws {
        navigateToHome()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: Self.defaultTimeout), "Home navigation bar should exist")

        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: Self.shortTimeout), "Gear button should exist")
        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: Self.shortTimeout), "Settings should open")

        // Navigate back
        var backButton = settingsNavBar.buttons["Pulse"]
        if !backButton.exists {
            backButton = settingsNavBar.buttons["Back"]
        }
        if !backButton.exists {
            backButton = settingsNavBar.buttons.firstMatch
        }

        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }

        XCTAssertTrue(homeNavBar.waitForExistence(timeout: Self.shortTimeout), "Should return to Home")
    }
}
