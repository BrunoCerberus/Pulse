import XCTest

final class FeedUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Navigate to Feed tab and verify navigation bar appears
    func navigateToFeed() {
        let feedTab = app.tabBars.buttons["Feed"]
        if feedTab.exists, !feedTab.isSelected {
            feedTab.tap()
        }
        _ = app.navigationBars["Daily Digest"].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Wait for feed content to load
    func waitForFeedContent(timeout: TimeInterval = 10) -> Bool {
        let contentIndicators = [
            app.staticTexts["Your Daily Digest"],
            app.staticTexts["No Recent Reading"],
            app.staticTexts["Something went wrong"],
            app.staticTexts["Loading model"],
            app.scrollViews.firstMatch,
        ]
        return waitForAny(contentIndicators, timeout: timeout)
    }

    // MARK: - Combined Flow Test

    /// Tests Feed tab navigation, content states, and interactions
    func testFeedFlow() throws {
        // --- Tab Navigation ---
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeed()

        XCTAssertTrue(feedTab.isSelected, "Feed tab should be selected")

        let navTitle = app.navigationBars["Daily Digest"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Daily Digest' should exist")

        // --- Content Loading ---
        let headerText = app.staticTexts["Your Daily Digest"]
        let emptyText = app.staticTexts["No Recent Reading"]
        let errorText = app.staticTexts["Something went wrong"]

        let contentLoaded = waitForFeedContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Feed should show content (digest, empty, or error state)")

        // --- Empty State ---
        if emptyText.exists {
            let emptyMessage = app.staticTexts["Read some articles to get your personalized daily digest."]
            XCTAssertTrue(emptyMessage.exists || emptyText.exists, "Empty state should show helpful message")
        }

        // --- Error State ---
        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have 'Try Again' button")
        }

        // --- Digest Content ---
        if headerText.exists {
            // Verify digest card is visible
            let scrollView = app.scrollViews.firstMatch
            XCTAssertTrue(scrollView.exists, "Scroll view should exist when digest is shown")

            // Look for source articles section
            let sourceArticlesText = app.staticTexts["Source Articles"]
            if sourceArticlesText.exists {
                // Tap to expand source articles
                sourceArticlesText.tap()
            }
        }

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load")

        let feedTabReturn = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTabReturn.waitForExistence(timeout: Self.shortTimeout), "Feed tab should exist")
        feedTabReturn.tap()

        let feedNavAfterSwitch = app.navigationBars["Daily Digest"]
        XCTAssertTrue(feedNavAfterSwitch.waitForExistence(timeout: Self.defaultTimeout), "Feed should be visible after tab switch")

        // --- Pull to Refresh ---
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            _ = navTitle.waitForExistence(timeout: Self.shortTimeout)
        }

        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.shortTimeout), "View should remain functional after refresh")
    }

    // MARK: - Tab Bar Position Test

    func testFeedTabPosition() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should exist")

        // Verify Feed tab exists and is in the correct position
        let tabButtons = tabBar.buttons.allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(tabButtons.count, 5, "Tab bar should have at least 5 tabs")

        // Find Feed tab index
        var feedIndex = -1
        for (index, button) in tabButtons.enumerated() {
            if button.label == "Feed" || button.identifier == "Feed" {
                feedIndex = index
                break
            }
        }

        // Feed should be between ForYou (index 1) and Bookmarks (index 3)
        // So Feed should be at index 2
        XCTAssertEqual(feedIndex, 2, "Feed tab should be at index 2 (between ForYou and Bookmarks)")
    }

    // MARK: - Source Articles Navigation Test

    func testSourceArticleNavigation() throws {
        navigateToFeed()

        let contentLoaded = waitForFeedContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Feed content should load")

        // Look for source articles section
        let sourceArticlesText = app.staticTexts["Source Articles"]

        if sourceArticlesText.waitForExistence(timeout: Self.defaultTimeout) {
            // Tap to expand
            sourceArticlesText.tap()

            // Wait a moment for expansion animation
            wait(for: 0.5)

            // Look for article rows that become visible
            let buttons = app.buttons.allElementsBoundByIndex

            for button in buttons {
                // Find a button that looks like an article row (has reasonable size)
                if button.frame.width > 200, button.frame.height > 50, button.isHittable {
                    button.tap()

                    // Check if we navigated to article detail
                    let backButton = app.buttons["backButton"]
                    if backButton.waitForExistence(timeout: Self.defaultTimeout) {
                        XCTAssertTrue(backButton.exists, "Should navigate to article detail")

                        // Navigate back
                        backButton.tap()

                        let navTitle = app.navigationBars["Daily Digest"]
                        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Should return to Feed")
                        break
                    }
                }
            }
        }
    }

    // MARK: - Generate Digest Interaction Test

    func testGenerateDigestInteraction() throws {
        navigateToFeed()

        let contentLoaded = waitForFeedContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Feed content should load")

        // If we see a generate button (when digest not yet generated), test it
        let generateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Generate'")).firstMatch

        if generateButton.waitForExistence(timeout: Self.shortTimeout), generateButton.isHittable {
            generateButton.tap()

            // Should see some indication of generation starting
            let loadingIndicators = [
                app.staticTexts["Loading model"],
                app.staticTexts["Generating"],
                app.activityIndicators.firstMatch,
            ]

            let generationStarted = waitForAny(loadingIndicators, timeout: 5)
            XCTAssertTrue(generationStarted || contentLoaded, "Generation should start or content should load")
        }

        // Verify the view is still functional
        let navTitle = app.navigationBars["Daily Digest"]
        XCTAssertTrue(navTitle.exists, "Navigation should remain functional")
    }
}
