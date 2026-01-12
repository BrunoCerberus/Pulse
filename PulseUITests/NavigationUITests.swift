import XCTest

final class NavigationUITests: BaseUITestCase {

    // MARK: - Combined Flow Test

    /// Tests tab bar existence, tab navigation, settings flow, and article detail navigation
    func testNavigationFlow() throws {
        // --- Tab Bar Exists ---
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should be visible after launch")

        // --- All Tabs Accessible ---
        let expectedTabs = ["Home", "For You", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.waitForExistence(timeout: Self.defaultTimeout), "Tab '\(tabName)' should exist in tab bar")
        }

        // --- Navigate to Each Tab and Verify ---
        // Home
        tabBar.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Home tab should display News navigation bar")

        // For You
        tabBar.buttons["For You"].tap()
        XCTAssertTrue(app.navigationBars["For You"].waitForExistence(timeout: Self.defaultTimeout), "For You tab should display For You navigation bar")

        // Bookmarks
        tabBar.buttons["Bookmarks"].tap()
        XCTAssertTrue(app.navigationBars["Bookmarks"].waitForExistence(timeout: Self.defaultTimeout), "Bookmarks tab should display Bookmarks navigation bar")

        // Search - tap elsewhere first to ensure no keyboard issues
        tabBar.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: Self.defaultTimeout), "Search tab should display Search navigation bar")

        // Dismiss keyboard if present before switching tabs
        if app.keyboards.element.exists {
            app.tap() // Tap outside to dismiss keyboard
            wait(for: 0.5)
        }

        // --- Tab Bar Still Visible After Search ---
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.defaultTimeout), "Tab bar should still be visible after Search tab")

        // --- Settings Navigation ---
        tabBar.buttons["Home"].tap()
        _ = app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout)

        navigateToSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: Self.defaultTimeout), "Settings should be accessible from Home")

        navigateBack()
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Should return to Home after navigating back from Settings")

        // --- Article Detail Navigation ---
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

                navigateBack()
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Should return to Home after navigating back from article")
            }
        }
    }
}
