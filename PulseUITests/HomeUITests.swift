import XCTest

final class HomeUITests: BaseUITestCase {

    // MARK: - Helper Methods

    private func navigateToHome() {
        navigateToTab("Home")
    }

    // MARK: - Navigation and Content Tests

    /// Tests navigation bar, content loading, interactions, and settings navigation
    func testHomeContentInteractionsAndSettingsFlow() throws {
        // Verify navigation title
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Navigation title 'News' should exist")

        // Verify gear button
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: Self.shortTimeout), "Gear button should exist in navigation bar")

        // Verify content loads
        let contentLoaded = waitForHomeContent(timeout: Self.defaultTimeout)
        XCTAssertTrue(contentLoaded, "Home should show content, empty state, or error state")

        // Check error state if present
        let errorState = app.staticTexts["Unable to Load News"].exists
        let emptyState = app.staticTexts["No News Available"].exists

        if errorState {
            XCTAssertTrue(app.buttons["Try Again"].exists, "Try Again button should exist in error state")
        }

        // --- Settings Navigation ---
        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: Self.defaultTimeout), "Settings should open")

        var settingsBackButton = settingsNavBar.buttons["Pulse"]
        if !settingsBackButton.exists {
            settingsBackButton = settingsNavBar.buttons["Back"]
        }
        if !settingsBackButton.exists {
            settingsBackButton = settingsNavBar.buttons.firstMatch
        }

        if settingsBackButton.exists {
            settingsBackButton.tap()
        } else {
            app.swipeRight()
        }

        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")

        if contentLoaded, !errorState, !emptyState {
            let cards = articleCards()
            XCTAssertTrue(cards.count > 0, "Article cards should exist when content loads")

            if cards.count > 0 {
                // --- Article Card Navigation ---
                let firstCard = cards.firstMatch
                XCTAssertTrue(firstCard.waitForExistence(timeout: Self.shortTimeout), "Article card should exist")

                // Scroll to make the card hittable if needed
                if !firstCard.isHittable {
                    app.scrollViews.firstMatch.swipeUp()
                }

                if firstCard.isHittable {
                    firstCard.tap()
                    XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                    // Navigate back
                    navigateBack()
                    XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")
                }

                // --- Scroll Interactions ---
                let scrollView = app.scrollViews.firstMatch
                XCTAssertTrue(scrollView.waitForExistence(timeout: Self.shortTimeout), "ScrollView should exist")

                // Pull to refresh
                scrollView.swipeDown()
                XCTAssertTrue(scrollView.exists, "ScrollView should still exist after refresh")

                // Vertical scroll
                scrollView.swipeUp()
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "App should remain responsive after scrolling")

                // Horizontal carousel scroll (if Breaking News exists)
                if app.staticTexts["Breaking News"].exists {
                    scrollView.swipeLeft()
                }

                // --- Context Menu ---
                let cardsAfterScroll = articleCards()
                if cardsAfterScroll.count > 0 {
                    cardsAfterScroll.firstMatch.press(forDuration: 0.5)

                    let contextMenuAppeared = app.buttons["Bookmark"].waitForExistence(timeout: Self.shortTimeout) ||
                        app.buttons["Share"].waitForExistence(timeout: 1)

                    if contextMenuAppeared {
                        app.tap() // Dismiss context menu
                    }
                }
            }
        }
    }
}
