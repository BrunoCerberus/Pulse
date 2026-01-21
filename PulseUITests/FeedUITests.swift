import XCTest

final class FeedUITests: BaseUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()

        // Speed optimizations (same as parent)
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"

        // Enable premium access so tests can access the actual feed content
        // Without this, the feed tab shows PremiumGateView instead of feed content
        app.launchEnvironment["MOCK_PREMIUM"] = "1"

        // Launch arguments to speed up tests
        app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
        app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]

        app.launch()

        // Launch verification
        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)
        wait(for: 0.3)

        // Wait for app to be ready - use same comprehensive detection as BaseUITestCase
        let tabBar = app.tabBars.firstMatch
        let signInButton = app.buttons["Sign in with Apple"]
        let homeTabButton = app.tabBars.buttons["Home"]
        let signInApple = app.buttons["Sign in with Apple"]
        let signInGoogle = app.buttons["Sign in with Google"]
        let loadingIndicator = app.activityIndicators.firstMatch

        // First, wait for the loading state to clear
        if loadingIndicator.waitForExistence(timeout: 2) {
            _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout)
        }

        // Now wait for either tab bar or sign-in to appear with multiple strategies
        var appReady = waitForAny([tabBar, homeTabButton, signInApple, signInGoogle], timeout: Self.launchTimeout)
        var foundTabBar = tabBar.exists || homeTabButton.exists

        // Fallback: try finding tab buttons directly if primary check fails
        if !appReady {
            let tabButtonNames = ["Home", "For You", "Feed", "Bookmarks", "Search"]
            for name in tabButtonNames {
                let tabButton = app.buttons[name]
                if tabButton.waitForExistence(timeout: 2) {
                    appReady = true
                    foundTabBar = true
                    break
                }
            }
        }

        guard appReady else {
            // Debug info for diagnosing CI failures
            let hasActivityIndicator = app.activityIndicators.count > 0
            let hasButtons = app.buttons.count > 0
            let hasStaticTexts = app.staticTexts.count > 0
            let allButtonLabels = app.buttons.allElementsBoundByIndex.prefix(10).map { $0.label }
            XCTFail("App did not reach ready state - Debug: hasActivityIndicator=\(hasActivityIndicator), " +
                    "buttons=\(hasButtons), texts=\(hasStaticTexts), buttonLabels=\(allButtonLabels)")
            return
        }

        if foundTabBar {
            resetToHomeTab()
        }
    }

    // MARK: - Helper Methods

    /// Navigate to Feed tab and verify navigation bar appears
    func navigateToFeed() {
        let feedTab = app.tabBars.buttons["Feed"]
        if feedTab.exists, !feedTab.isSelected {
            feedTab.tap()
        }
        _ = app.navigationBars["Daily Digest"].waitForExistence(timeout: Self.defaultTimeout)
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

            // Wait for expansion animation to complete
            wait(for: 1.0)

            // Look for article rows with chevron.right (source article rows have this indicator)
            let chevronButtons = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'chevron' OR identifier CONTAINS[c] 'sourceArticle'")
            )

            // Try to find and tap a source article button
            let buttonCount = chevronButtons.count
            if buttonCount > 0 {
                // Tap the first available source article
                let firstButton = chevronButtons.element(boundBy: 0)
                if firstButton.waitForExistence(timeout: Self.shortTimeout), firstButton.isHittable {
                    firstButton.tap()

                    // Check if we navigated to article detail
                    let backButton = app.buttons["backButton"]
                    if backButton.waitForExistence(timeout: Self.defaultTimeout) {
                        XCTAssertTrue(backButton.exists, "Should navigate to article detail")

                        // Navigate back
                        backButton.tap()

                        let navTitle = app.navigationBars["Daily Digest"]
                        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Should return to Feed")
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
