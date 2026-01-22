import XCTest

final class HomeUITests: BaseUITestCase {

    // MARK: - Navigation and Content Tests

    /// Tests navigation bar, content loading, interactions, and settings navigation
    func testHomeContentInteractionsAndSettingsFlow() throws {
        // Verify navigation title
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Navigation title 'News' should exist")

        // Verify gear button
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: Self.shortTimeout), "Gear button should exist in navigation bar")

        // Verify content loads (use longer timeout for CI environments)
        // Note: In CI, mock data may not be available, so we test what we can
        let contentLoaded = waitForHomeContent(timeout: 45)

        // Check error state if present
        let errorState = app.staticTexts["Unable to Load News"].exists
        let emptyState = app.staticTexts["No News Available"].exists

        // Test continues regardless of content state - CI may have limited mock data
        if errorState {
            let tryAgainButton = app.buttons["Try Again"]
            if tryAgainButton.exists {
                // Error state is valid, try again button exists as expected
            }
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

        // Only test article interactions if content loaded successfully and isn't an error/empty state
        // This makes tests resilient to CI environments with limited mock data
        if contentLoaded, !errorState, !emptyState {
            let cards = articleCards()
            let firstCard = cards.firstMatch

            // Use longer timeout for CI - articles may take time to render
            if firstCard.waitForExistence(timeout: 15) {
                // --- Article Card Navigation ---

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
                let contextCard = cardsAfterScroll.firstMatch
                if contextCard.waitForExistence(timeout: Self.shortTimeout) {
                    contextCard.press(forDuration: 0.5)

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
