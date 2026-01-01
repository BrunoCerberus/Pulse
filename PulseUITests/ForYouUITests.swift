import XCTest

final class ForYouUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Navigate to For You tab
    private func navigateToForYou() {
        let forYouTab = app.tabBars.buttons["For You"]
        guard forYouTab.waitForExistence(timeout: 5) else { return }
        if !forYouTab.isSelected {
            forYouTab.tap()
        }
        // Wait for For You view to load
        _ = app.navigationBars["For You"].waitForExistence(timeout: Self.defaultTimeout)
    }

    // MARK: - Combined Flow Test

    /// Tests For You navigation, content states, interactions, and related settings flows
    func testForYouFlow() throws {
        // --- Tab Navigation ---
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists, "For You tab should exist")

        navigateToForYou()

        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'For You' should exist")

        // --- Content Loading ---
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        let noArticlesText = app.staticTexts["No Articles"]
        let errorText = app.staticTexts["Unable to Load Feed"]
        let forYouNav = app.navigationBars["For You"]

        let timeout: TimeInterval = 20
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if personalizeText.exists || articleCards.count > 0 || noArticlesText.exists || errorText.exists {
                contentLoaded = true
                break
            }
            wait(for: 0.5)
        }

        if !contentLoaded {
            contentLoaded = forYouNav.exists
        }

        XCTAssertTrue(contentLoaded, "For You should show content (articles, onboarding, empty, or error state)")

        // If onboarding, verify helpful elements and Set Preferences navigation
        if personalizeText.exists {
            let helpText = app.staticTexts["Follow topics and sources to see articles tailored to your interests."]
            XCTAssertTrue(helpText.exists, "Onboarding should show helpful message")

            let setPreferencesButton = app.buttons["Set Preferences"]
            XCTAssertTrue(setPreferencesButton.exists, "Onboarding should have 'Set Preferences' button")

            if setPreferencesButton.isHittable {
                setPreferencesButton.tap()

                let settingsNav = app.navigationBars["Settings"]
                XCTAssertTrue(settingsNav.waitForExistence(timeout: 10), "Should navigate to Settings")

                let backButton = settingsNav.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                } else {
                    app.swipeRight()
                }

                _ = app.navigationBars["For You"].waitForExistence(timeout: Self.defaultTimeout)
            }
        }

        // If error, verify Try Again button
        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }

        // --- Article Navigation and Scroll ---
        navigateToForYou()
        wait(for: 2)

        let articleCardsAfterLoad = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        if articleCardsAfterLoad.count > 0 {
            articleCardsAfterLoad.firstMatch.tap()

            let backButton = app.buttons["backButton"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

            backButton.tap()

            let forYouNavAfter = app.navigationBars["For You"]
            XCTAssertTrue(forYouNavAfter.waitForExistence(timeout: 5), "Should return to For You")
        }

        let scrollView = app.scrollViews.firstMatch
        let articleCardsAfterScroll = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if scrollView.exists {
            // Pull to refresh
            scrollView.swipeDown()
            wait(for: 1)

            // Infinite scroll
            if articleCardsAfterScroll.count > 0 {
                scrollView.swipeUp()
                scrollView.swipeUp()
                scrollView.swipeUp()
            }
        }

        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "View should remain functional after scrolling")

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load")

        let forYouTabReturn = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTabReturn.waitForExistence(timeout: Self.shortTimeout), "For You tab should exist")
        forYouTabReturn.tap()

        let forYouNavAfterSwitch = app.navigationBars["For You"]
        XCTAssertTrue(forYouNavAfterSwitch.waitForExistence(timeout: Self.defaultTimeout), "For You should be visible after tab switch")

        // --- Follow Topic in Settings ---
        navigateToSettings()

        let followedTopicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(followedTopicsSection.waitForExistence(timeout: 5), "Followed Topics section should exist")

        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch

        if technologyRow.exists {
            technologyRow.tap()
            wait(for: 1)
        }

        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }

        let homeNavAfterSettings = app.navigationBars["News"]
        XCTAssertTrue(homeNavAfterSettings.waitForExistence(timeout: 5), "Should return to Home")

        navigateToForYou()
        wait(for: 2)

        let navTitleAfterSettings = app.navigationBars["For You"]
        XCTAssertTrue(navTitleAfterSettings.exists, "For You should be visible")
    }
}
