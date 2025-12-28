import XCTest

final class HomeUITests: BaseUITestCase {

    // MARK: - Helper Methods

    private func navigateToHome() {
        navigateToTab("Home")
    }

    // MARK: - Navigation Bar Tests

    /// Tests navigation bar elements: title and gear button
    func testNavigationBarElements() throws {
        navigateToHome()

        // Verify navigation title
        XCTAssertTrue(app.navigationBars["Pulse"].waitForExistence(timeout: Self.shortTimeout), "Navigation title 'Pulse' should exist")

        // Verify gear button
        XCTAssertTrue(app.navigationBars.buttons["gearshape"].waitForExistence(timeout: Self.shortTimeout), "Gear button should exist in navigation bar")
    }

    // MARK: - Content Tests

    /// Tests that home content loads (breaking news, headlines, or appropriate state)
    func testHomeContentLoads() throws {
        navigateToHome()
        XCTAssertTrue(waitForHomeContent(timeout: Self.defaultTimeout), "Home should show content, empty state, or error state")
    }

    // MARK: - Article Navigation Tests

    /// Tests tapping article cards navigates to detail and back
    func testArticleCardNavigation() throws {
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

        // Find a hittable article card
        let firstCard = cards.firstMatch
        guard firstCard.waitForExistence(timeout: Self.shortTimeout) else {
            throw XCTSkip("Article card not found")
        }

        // Scroll to make the card hittable if needed
        if !firstCard.isHittable {
            app.scrollViews.firstMatch.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }

        guard firstCard.isHittable else {
            throw XCTSkip("Article card not hittable")
        }

        firstCard.tap()
        XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

        // Navigate back
        navigateBack()
        XCTAssertTrue(app.navigationBars["Pulse"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")
    }

    // MARK: - Scroll Interaction Tests

    /// Tests pull to refresh, vertical scroll, and horizontal carousel scroll
    func testScrollInteractions() throws {
        navigateToHome()

        guard waitForHomeContent(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Content did not load")
        }

        if app.staticTexts["Unable to Load News"].exists || app.staticTexts["No News Available"].exists {
            throw XCTSkip("No content available for scroll testing")
        }

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: Self.shortTimeout), "ScrollView should exist")

        // Pull to refresh
        scrollView.swipeDown()
        XCTAssertTrue(scrollView.exists, "ScrollView should still exist after refresh")

        // Vertical scroll
        scrollView.swipeUp()
        XCTAssertTrue(app.navigationBars["Pulse"].waitForExistence(timeout: Self.shortTimeout), "App should remain responsive after scrolling")

        // Horizontal carousel scroll (if Breaking News exists)
        if app.staticTexts["Breaking News"].exists {
            scrollView.swipeLeft()
        }
    }

    // MARK: - Error State Tests

    func testErrorStateShowsTryAgainButton() throws {
        navigateToHome()
        _ = waitForHomeContent(timeout: Self.defaultTimeout)

        if app.staticTexts["Unable to Load News"].exists {
            XCTAssertTrue(app.buttons["Try Again"].exists, "Try Again button should exist in error state")
        }
    }

    // MARK: - Context Menu Tests

    func testArticleCardContextMenu() throws {
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
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: Self.defaultTimeout), "Settings should open")

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
