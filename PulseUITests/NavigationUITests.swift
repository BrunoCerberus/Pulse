import XCTest

final class NavigationUITests: BaseUITestCase {

    // MARK: - Tab Bar Navigation Tests

    func testTabBarExists() {
        // Verify tab bar is visible after app launch
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist on home screen")
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should be visible after launch")
    }

    func testAllTabsAreAccessible() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let expectedTabs = ["Home", "For You", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Tab '\(tabName)' should exist in tab bar")
        }
    }

    func testNavigateToHomeTab() {
        navigateToTab("Home")
        let navBar = app.navigationBars["News"]
        XCTAssertTrue(navBar.waitForExistence(timeout: Self.shortTimeout), "Home tab should display News navigation bar")
    }

    func testNavigateToForYouTab() {
        navigateToForYouTab()
        let navBar = app.navigationBars["For You"]
        XCTAssertTrue(navBar.exists, "For You tab should display For You navigation bar")
    }

    func testNavigateToBookmarksTab() {
        navigateToBookmarksTab()
        let navBar = app.navigationBars["Bookmarks"]
        XCTAssertTrue(navBar.exists, "Bookmarks tab should display Bookmarks navigation bar")
    }

    func testNavigateToSearchTab() {
        navigateToSearchTab()
        let searchNavBar = app.navigationBars["Search"]
        XCTAssertTrue(searchNavBar.exists, "Search tab should display Search navigation bar")
    }

    // MARK: - Tab Switching Tests

    func testTabSwitchingFromHomeToForYou() {
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].exists, "Should start on Home tab")

        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].exists, "Should switch to For You tab")

        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].exists, "Should switch back to Home tab")
    }

    func testTabPersistence() {
        // Navigate to For You tab
        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].exists, "Should be on For You tab")

        // Switch to another tab
        navigateToBookmarksTab()
        XCTAssertTrue(app.navigationBars["Bookmarks"].exists, "Should be on Bookmarks tab")

        // Return to For You - state should persist
        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].exists, "Should return to For You tab")
    }

    // MARK: - Settings Navigation Tests

    func testNavigateToSettingsFromHome() {
        navigateToSettings()
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.exists, "Settings should be accessible from Home")
    }

    func testSettingsBackNavigation() {
        navigateToSettings()
        XCTAssertTrue(app.navigationBars["Settings"].exists, "Settings should be open")

        navigateBack()
        let homeNavBar = app.navigationBars["News"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: Self.shortTimeout), "Should return to Home after navigating back from Settings")
    }

    // MARK: - Deep Navigation Tests

    func testNavigateToArticleDetail() {
        navigateToTab("Home")
        waitForHomeContent(timeout: 20)

        let articleCards = self.articleCards()
        let firstCard = articleCards.firstMatch

        if firstCard.waitForExistence(timeout: Self.defaultTimeout) {
            // Ensure card is hittable
            if !firstCard.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }

            if firstCard.isHittable {
                firstCard.tap()
                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")
            }
        }
    }

    func testNavigateBackFromArticleDetail() {
        navigateToTab("Home")
        waitForHomeContent(timeout: 20)

        let articleCards = self.articleCards()
        let firstCard = articleCards.firstMatch

        if firstCard.waitForExistence(timeout: Self.defaultTimeout) {
            if !firstCard.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }

            if firstCard.isHittable {
                firstCard.tap()
                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                navigateBack()
                let homeNavBar = app.navigationBars["News"]
                XCTAssertTrue(homeNavBar.waitForExistence(timeout: Self.shortTimeout), "Should return to Home after navigating back from article")
            }
        }
    }

    // MARK: - Tab Retention After Navigation

    func testTabRetentionAfterDeepNavigation() {
        // Verify we're on Home
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].exists, "Should be on Home tab")

        // Navigate to an article
        waitForHomeContent(timeout: 20)
        let articleCards = self.articleCards()
        if articleCards.firstMatch.waitForExistence(timeout: Self.defaultTimeout) {
            if articleCards.firstMatch.isHittable {
                articleCards.firstMatch.tap()
                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")
            }
        }

        // Navigate back - tab should still be Home
        navigateBack()
        XCTAssertTrue(app.navigationBars["News"].exists, "Should return to Home tab after deep navigation")
    }

    // MARK: - Tab Bar Visibility Tests

    func testTabBarRemainsVisibleOnAllTabs() {
        let tabBar = app.tabBars.firstMatch
        let tabs = ["Home", "For You", "Bookmarks", "Search"]

        for tabName in tabs {
            navigateToTab(tabName)
            XCTAssertTrue(tabBar.exists, "Tab bar should remain visible on \(tabName) tab")
        }
    }
}
