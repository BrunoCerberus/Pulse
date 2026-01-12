import XCTest

final class NavigationUITests: BaseUITestCase {

    // MARK: - Helper

    /// Force tap a tab and wait for its navigation bar
    private func switchToTab(_ tabName: String, expectedNavBar: String) {
        let tab = app.tabBars.buttons[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: Self.defaultTimeout), "\(tabName) tab should exist")
        tab.tap()
        wait(for: 0.3) // Allow tab switch animation
        XCTAssertTrue(
            app.navigationBars[expectedNavBar].waitForExistence(timeout: Self.defaultTimeout),
            "Should show \(expectedNavBar) navigation bar after switching to \(tabName) tab"
        )
    }

    // MARK: - Combined Flow Test

    /// Tests tab bar, tab navigation, settings flow, article detail navigation, and state persistence
    func testNavigationFlow() throws {
        // --- Tab Bar Exists ---
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should be visible after launch")

        // --- All Tabs Accessible ---
        let expectedTabs = ["Home", "For You", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Tab '\(tabName)' should exist in tab bar")
        }

        // --- Navigate Through All Tabs ---
        switchToTab("Home", expectedNavBar: "News")
        switchToTab("For You", expectedNavBar: "For You")
        switchToTab("Bookmarks", expectedNavBar: "Bookmarks")
        switchToTab("Search", expectedNavBar: "Search")

        // --- Tab Switching (Search -> Home -> For You -> Home) ---
        switchToTab("Home", expectedNavBar: "News")
        switchToTab("For You", expectedNavBar: "For You")
        switchToTab("Home", expectedNavBar: "News")

        // --- Tab Persistence ---
        switchToTab("For You", expectedNavBar: "For You")
        switchToTab("Bookmarks", expectedNavBar: "Bookmarks")
        switchToTab("For You", expectedNavBar: "For You")

        // --- Settings Navigation ---
        navigateToSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: Self.defaultTimeout), "Settings should be accessible from Home")

        navigateBack()
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Should return to Home after navigating back from Settings")

        // --- Tab Bar Visibility on All Tabs ---
        for tabName in expectedTabs {
            app.tabBars.buttons[tabName].tap()
            wait(for: 0.3)
            XCTAssertTrue(tabBar.exists, "Tab bar should remain visible on \(tabName) tab")
        }

        // --- Article Detail Navigation ---
        switchToTab("Home", expectedNavBar: "News")
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
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Should return to Home after navigating back from article")

                // --- Tab Retention After Deep Navigation ---
                if firstCard.waitForExistence(timeout: Self.defaultTimeout), firstCard.isHittable {
                    firstCard.tap()
                    XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail again")

                    navigateBack()
                    XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.defaultTimeout), "Should return to Home tab after deep navigation")
                }
            }
        }
    }
}
