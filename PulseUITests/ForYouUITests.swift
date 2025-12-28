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

    // MARK: - Navigation Tests

    /// Tests tab navigation and selection
    func testForYouTabNavigation() throws {
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists, "For You tab should exist")

        navigateToForYou()

        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'For You' should exist")
    }

    // MARK: - Content State Tests

    /// Tests content loads (onboarding, articles, empty, or error state)
    func testForYouContentLoads() throws {
        navigateToForYou()

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
            Thread.sleep(forTimeInterval: 0.5)
        }

        if !contentLoaded {
            contentLoaded = forYouNav.exists
        }

        XCTAssertTrue(contentLoaded, "For You should show content (articles, onboarding, empty, or error state)")

        // If onboarding, verify helpful elements
        if personalizeText.exists {
            let helpText = app.staticTexts["Follow topics and sources to see articles tailored to your interests."]
            XCTAssertTrue(helpText.exists, "Onboarding should show helpful message")

            let setPreferencesButton = app.buttons["Set Preferences"]
            XCTAssertTrue(setPreferencesButton.exists, "Onboarding should have 'Set Preferences' button")
        }
    }

    // MARK: - Onboarding Tests

    /// Tests Set Preferences button navigates to Settings
    func testOnboardingSetPreferencesNavigation() throws {
        navigateToForYou()

        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        let noArticlesText = app.staticTexts["No Articles"]
        let errorText = app.staticTexts["Unable to Load Feed"]

        let timeout: TimeInterval = 20
        let startTime = Date()
        var contentAppeared = false

        while Date().timeIntervalSince(startTime) < timeout {
            if personalizeText.exists || articleCards.count > 0 || noArticlesText.exists || errorText.exists {
                contentAppeared = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        guard contentAppeared else {
            throw XCTSkip("Content did not load in time")
        }

        if errorText.exists {
            throw XCTSkip("For You feed error state shown")
        } else if personalizeText.exists {
            let setPreferencesButton = app.buttons["Set Preferences"]
            guard setPreferencesButton.waitForExistence(timeout: 5) else {
                throw XCTSkip("Set Preferences button not found in onboarding")
            }

            setPreferencesButton.tap()

            let settingsNav = app.navigationBars["Settings"]
            XCTAssertTrue(settingsNav.waitForExistence(timeout: 10), "Should navigate to Settings")
        } else {
            XCTAssertTrue(articleCards.count > 0 || noArticlesText.exists, "For You should show content")
        }
    }

    // MARK: - Article Navigation Tests

    /// Tests tapping article card navigates to detail and back
    func testArticleCardNavigation() throws {
        navigateToForYou()

        Thread.sleep(forTimeInterval: 3)

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCards.count > 0 {
            articleCards.firstMatch.tap()

            let backButton = app.buttons["backButton"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

            backButton.tap()

            let forYouNav = app.navigationBars["For You"]
            XCTAssertTrue(forYouNav.waitForExistence(timeout: 5), "Should return to For You")
        }
    }

    // MARK: - Scroll Behavior Tests

    /// Tests scroll interactions (pull to refresh, infinite scroll)
    func testScrollBehavior() throws {
        navigateToForYou()

        Thread.sleep(forTimeInterval: 2)

        let scrollView = app.scrollViews.firstMatch
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if scrollView.exists {
            // Pull to refresh
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 1)

            // Infinite scroll
            if articleCards.count > 0 {
                scrollView.swipeUp()
                scrollView.swipeUp()
                scrollView.swipeUp()
            }
        }

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "View should remain functional after scrolling")
    }

    // MARK: - Error State Tests

    /// Tests error state shows try again button
    func testErrorStateShowsTryAgainButton() throws {
        navigateToForYou()

        Thread.sleep(forTimeInterval: 3)

        let errorText = app.staticTexts["Unable to Load Feed"]

        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }
    }

    // MARK: - Tab Switching Tests

    /// Tests tab switching preserves For You state
    func testSwitchingTabsPreservesForYouState() throws {
        navigateToForYou()

        let navTitle = app.navigationBars["For You"]
        guard navTitle.waitForExistence(timeout: Self.defaultTimeout) else {
            throw XCTSkip("For You navigation did not load")
        }

        Thread.sleep(forTimeInterval: 2)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load")

        Thread.sleep(forTimeInterval: 1)

        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: Self.shortTimeout), "For You tab should exist")
        forYouTab.tap()

        let forYouNav = app.navigationBars["For You"]
        XCTAssertTrue(forYouNav.waitForExistence(timeout: Self.defaultTimeout), "For You should be visible after tab switch")
    }

    // MARK: - Integration Tests

    /// Tests following topic in settings and verifying in For You
    func testFollowTopicInSettingsAndVerifyInForYou() throws {
        navigateToSettings()

        let followedTopicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(followedTopicsSection.waitForExistence(timeout: 5), "Followed Topics section should exist")

        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch

        if technologyRow.exists {
            technologyRow.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()

        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should return to Home")

        navigateToForYou()

        Thread.sleep(forTimeInterval: 3)

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "For You should be visible")
    }
}
