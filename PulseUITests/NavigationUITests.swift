import XCTest

final class NavigationUITests: BaseUITestCase {

    // MARK: - Combined Flow Test

    /// Tests tab bar, tab navigation, settings flow, article detail navigation, and state persistence
    func testNavigationFlow() throws {
        // --- Tab Bar Exists ---
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist on home screen")
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should be visible after launch")

        // --- All Tabs Accessible ---
        let expectedTabs = ["Home", "For You", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Tab '\(tabName)' should exist in tab bar")
        }

        // --- Navigate to Home Tab ---
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Home tab should display News navigation bar")

        // --- Navigate to For You Tab ---
        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].exists, "For You tab should display For You navigation bar")

        // --- Navigate to Bookmarks Tab ---
        navigateToBookmarksTab()
        XCTAssertTrue(app.navigationBars["Bookmarks"].exists, "Bookmarks tab should display Bookmarks navigation bar")

        // --- Navigate to Search Tab ---
        navigateToSearchTab()
        XCTAssertTrue(app.navigationBars["Search"].exists, "Search tab should display Search navigation bar")

        // --- Tab Switching (Home <-> For You) ---
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should be on Home tab")

        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].waitForExistence(timeout: Self.shortTimeout), "Should switch to For You tab")

        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should switch back to Home tab")

        // --- Tab Persistence ---
        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].waitForExistence(timeout: Self.shortTimeout), "Should be on For You tab")

        navigateToBookmarksTab()
        XCTAssertTrue(app.navigationBars["Bookmarks"].waitForExistence(timeout: Self.shortTimeout), "Should be on Bookmarks tab")

        navigateToForYouTab()
        XCTAssertTrue(app.navigationBars["For You"].waitForExistence(timeout: Self.shortTimeout), "Should return to For You tab")

        // --- Settings Navigation ---
        navigateToSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: Self.shortTimeout), "Settings should be accessible from Home")

        navigateBack()
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home after navigating back from Settings")

        // --- Tab Bar Visibility on All Tabs ---
        for tabName in expectedTabs {
            navigateToTab(tabName)
            XCTAssertTrue(tabBar.exists, "Tab bar should remain visible on \(tabName) tab")
        }

        // --- Article Detail Navigation ---
        navigateToTab("Home")
        waitForHomeContent(timeout: 20)

        let cards = articleCards()
        let firstCard = cards.firstMatch

        if firstCard.waitForExistence(timeout: Self.defaultTimeout) {
            if !firstCard.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }

            if firstCard.isHittable {
                firstCard.tap()
                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                // --- Navigate Back from Article Detail ---
                navigateBack()
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home after navigating back from article")

                // --- Tab Retention After Deep Navigation ---
                firstCard.tap()
                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail again")

                navigateBack()
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home tab after deep navigation")
            }
        }
    }
}
