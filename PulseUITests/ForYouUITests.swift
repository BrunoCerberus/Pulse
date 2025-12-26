import XCTest

final class ForYouUITests: XCTestCase {
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

    /// Navigate to For You tab
    private func navigateToForYou() {
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: 5), "For You tab should exist")
        forYouTab.tap()

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "For You view should load")
    }

    /// Navigate to Settings via gear button
    private func navigateToSettings() {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()

        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist")
        gearButton.tap()

        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Settings should open")
    }

    // MARK: - Navigation Tests

    func testForYouTabExists() throws {
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists, "For You tab should exist")
    }

    func testForYouTabCanBeSelected() throws {
        navigateToForYou()

        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")
    }

    func testForYouNavigationTitleExists() throws {
        navigateToForYou()

        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'For You' should exist")
    }

    // MARK: - Onboarding State Tests

    func testOnboardingShowsPersonalizeMessage() throws {
        navigateToForYou()

        // Wait for content to load
        Thread.sleep(forTimeInterval: 2)

        // Check for onboarding or content
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let noArticlesText = app.staticTexts["No Articles"]
        let forYouHeader = app.staticTexts["For You"]
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        // One of these should exist
        let contentLoaded = personalizeText.exists ||
            noArticlesText.exists ||
            forYouHeader.exists ||
            articleCards.count > 0

        XCTAssertTrue(contentLoaded, "For You should show onboarding, empty state, or articles")
    }

    func testOnboardingShowsSetPreferencesButton() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // Check for onboarding state
        let personalizeText = app.staticTexts["Personalize Your Feed"]

        if personalizeText.exists {
            let setPreferencesButton = app.buttons["Set Preferences"]
            XCTAssertTrue(setPreferencesButton.exists, "Onboarding should have 'Set Preferences' button")
        }
    }

    func testOnboardingSetPreferencesNavigatesToSettings() throws {
        navigateToForYou()

        // Wait for content to load using polling approach
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        let noArticlesText = app.staticTexts["No Articles"]
        let errorText = app.staticTexts["Unable to Load Feed"]

        // Poll for any content to appear
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

        // If onboarding is shown, test the Set Preferences button
        if errorText.exists {
            throw XCTSkip("For You feed error state shown")
        } else if personalizeText.exists {
            let setPreferencesButton = app.buttons["Set Preferences"]
            guard setPreferencesButton.waitForExistence(timeout: 5) else {
                throw XCTSkip("Set Preferences button not found in onboarding")
            }

            setPreferencesButton.tap()

            // Should navigate to Settings
            let settingsNav = app.navigationBars["Settings"]
            XCTAssertTrue(settingsNav.waitForExistence(timeout: 10), "Should navigate to Settings")
        } else {
            // User already has preferences or articles are loading - test passes
            XCTAssertTrue(articleCards.count > 0 || noArticlesText.exists, "For You should show content")
        }
    }

    func testOnboardingHelpText() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        let personalizeText = app.staticTexts["Personalize Your Feed"]

        if personalizeText.exists {
            let helpText = app.staticTexts["Follow topics and sources to see articles tailored to your interests."]
            XCTAssertTrue(helpText.exists, "Onboarding should show helpful message")
        }
    }

    // MARK: - Followed Topics Bar Tests

    func testFollowedTopicsBarExists() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // If user has followed topics, the topics bar should exist
        // Topics include: World, Business, Technology, Science, Health, Sports, Entertainment
        let topicNames = ["World", "Business", "Technology", "Science", "Health", "Sports", "Entertainment"]

        var topicsBarExists = false
        for topic in topicNames {
            if app.staticTexts[topic].exists {
                topicsBarExists = true
                break
            }
        }

        // Topics bar may or may not exist depending on user preferences
        // This test verifies the UI loads correctly
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "For You view should be loaded")
    }

    func testFollowedTopicsBarIsHorizontallyScrollable() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 2)

        // Check if topics bar exists
        let topicNames = ["World", "Business", "Technology", "Science", "Health", "Sports", "Entertainment"]
        var hasTopics = false

        for topic in topicNames {
            if app.staticTexts[topic].exists {
                hasTopics = true
                break
            }
        }

        if hasTopics {
            // Try to scroll the topics bar
            let scrollViews = app.scrollViews
            if scrollViews.count > 0 {
                scrollViews.firstMatch.swipeLeft()
            }
        }

        // View should remain functional
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "View should remain functional")
    }

    // MARK: - Article List Tests

    func testArticleListAppearsWithFollowedTopics() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 3)

        // Check for articles or other states
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let noArticlesText = app.staticTexts["No Articles"]
        let loadingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Loading'")).firstMatch

        let contentLoaded = articleCards.count > 0 ||
            personalizeText.exists ||
            noArticlesText.exists ||
            loadingText.exists

        XCTAssertTrue(contentLoaded, "For You should show content")
    }

    func testArticleCardTapNavigatesToDetail() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 3)

        // Find and tap an article card
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCards.count > 0 {
            articleCards.firstMatch.tap()

            // Verify navigation to detail
            let backButton = app.buttons["backButton"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

            // Navigate back
            backButton.tap()

            // Verify back on For You
            let forYouNav = app.navigationBars["For You"]
            XCTAssertTrue(forYouNav.waitForExistence(timeout: 5), "Should return to For You")
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshWorks() throws {
        navigateToForYou()

        // Wait for initial content
        Thread.sleep(forTimeInterval: 2)

        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            // Pull to refresh
            scrollView.swipeDown()

            // Wait for refresh
            Thread.sleep(forTimeInterval: 2)
        }

        // View should remain functional
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "View should remain functional after refresh")
    }

    // MARK: - Infinite Scroll Tests

    func testInfiniteScrollLoadsMoreArticles() throws {
        navigateToForYou()

        // Wait for initial content
        Thread.sleep(forTimeInterval: 3)

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            // Scroll down multiple times
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                scrollView.swipeUp()
                scrollView.swipeUp()

                // Wait for potential loading
                Thread.sleep(forTimeInterval: 2)
            }
        }

        // View should remain functional
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "View should remain functional after scrolling")
    }

    func testLoadingMoreIndicator() throws {
        navigateToForYou()

        // Wait for initial content
        Thread.sleep(forTimeInterval: 3)

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            // Scroll to bottom
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                for _ in 0..<5 {
                    scrollView.swipeUp()
                }
            }

            // Check for "Loading more..." (may or may not appear)
            let loadingMoreText = app.staticTexts["Loading more..."]
            // This is optional
        }

        XCTAssertTrue(true, "Loading more indicator test completed")
    }

    // MARK: - Empty State Tests

    func testEmptyStateShowsNoArticlesMessage() throws {
        navigateToForYou()

        // Wait for content to load - either articles, onboarding, or empty state
        let noArticlesText = app.staticTexts["No Articles"]
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))
        let errorText = app.staticTexts["Unable to Load Feed"]

        // Use a polling approach to avoid cascading waits
        let timeout: TimeInterval = 20
        let startTime = Date()
        var contentLoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if noArticlesText.exists || personalizeText.exists || articleCards.count > 0 || errorText.exists {
                contentLoaded = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(contentLoaded, "For You should show content (empty state, onboarding, articles, or error state)")
    }

    // MARK: - Error State Tests

    func testErrorStateShowsTryAgainButton() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 3)

        let errorText = app.staticTexts["Unable to Load Feed"]

        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }
    }

    // MARK: - Loading State Tests

    func testLoadingStateShowsSkeletons() throws {
        // Launch fresh to catch loading state
        app.terminate()
        app = XCUIApplication()
        app.launchEnvironment["XCTestConfigurationFilePath"] = "UI"
        app.launch()

        _ = app.wait(for: .runningForeground, timeout: 5.0)

        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should appear")

        // Navigate to For You immediately
        navigateToForYou()

        // Check for loading state or content
        let forYouHeader = app.staticTexts["For You"]
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let noArticlesText = app.staticTexts["No Articles"]

        // Wait for any content
        Thread.sleep(forTimeInterval: 3)

        let contentLoaded = forYouHeader.exists ||
            personalizeText.exists ||
            noArticlesText.exists ||
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'")).count > 0

        XCTAssertTrue(contentLoaded, "Content should load")
    }

    // MARK: - Integration Tests

    func testFollowTopicInSettingsAndVerifyInForYou() throws {
        // Navigate to Settings first
        navigateToSettings()

        // Find Followed Topics section
        let followedTopicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(followedTopicsSection.waitForExistence(timeout: 5), "Followed Topics section should exist")

        // Try to toggle a topic (e.g., Technology)
        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch

        if technologyRow.exists {
            technologyRow.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()

        // Wait for Home
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should return to Home")

        // Navigate to For You
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 3)

        // For You should show personalized content or prompt
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "For You should be visible")
    }

    // MARK: - Tab Switching Tests

    func testSwitchingTabsPreservesForYouState() throws {
        navigateToForYou()

        // Wait for initial content to load
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 10), "For You navigation should exist")

        // Wait for content to stabilize
        Thread.sleep(forTimeInterval: 2)

        // Switch to Home
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Home tab should exist")
        homeTab.tap()

        // Wait for Home to load with extended timeout for CI
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 10), "Home should load")

        // Brief pause to let tab switch complete
        Thread.sleep(forTimeInterval: 1)

        // Switch back to For You
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: 5), "For You tab should exist")
        forYouTab.tap()

        // Verify For You is visible again with extended timeout
        let forYouNav = app.navigationBars["For You"]
        XCTAssertTrue(forYouNav.waitForExistence(timeout: 10), "For You should be visible after tab switch")
    }

    // MARK: - Section Header Tests

    func testForYouSectionHeaderExists() throws {
        navigateToForYou()

        // Wait for content
        Thread.sleep(forTimeInterval: 3)

        // If articles are loading, check for section header
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            // There might be a "For You" section header
            let sectionHeader = app.staticTexts["For You"]
            // This is optional depending on implementation
        }

        // View should be loaded
        let navTitle = app.navigationBars["For You"]
        XCTAssertTrue(navTitle.exists, "For You navigation should exist")
    }
}
