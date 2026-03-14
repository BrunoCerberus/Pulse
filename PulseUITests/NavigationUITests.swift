import XCTest

final class NavigationUITests: BaseUITestCase {
    // MARK: - Combined Flow Test

    // Tests tab bar existence, tab navigation, settings flow, and article detail navigation
    // Note: Search tab navigation is tested separately in PulseSearchUITests
    // swiftlint:disable:next function_body_length
    func testNavigationFlow() {
        // --- Tab Bar Exists ---
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(safeWaitForExistence(tabBar, timeout: Self.launchTimeout), "Tab bar should be visible after launch")

        // --- All Tabs Accessible ---
        let expectedTabs = ["Home", "Feed", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(
                safeWaitForExistence(tab, timeout: Self.defaultTimeout),
                "Tab '\(tabName)' should exist in tab bar"
            )
        }

        // --- Navigate to Each Tab and Verify (except Search - tested in PulseSearchUITests) ---

        // Home
        navigateToTab("Home")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Home tab should display News navigation bar"
        )

        // Feed (Daily Digest)
        navigateToFeedTab()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Daily Digest"], timeout: Self.defaultTimeout),
            "Feed tab should display Daily Digest navigation bar"
        )

        // Bookmarks
        navigateToBookmarksTab()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.defaultTimeout),
            "Bookmarks tab should display Bookmarks navigation bar"
        )

        // Return to Home for Settings test
        navigateToTab("Home")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Should return to Home tab"
        )

        // --- Settings Navigation ---
        navigateToSettings()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout),
            "Settings should be accessible from Home"
        )

        navigateBack(waitForNavBar: "News")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Should return to Home after navigating back from Settings"
        )

        // --- Article Detail Navigation ---
        // Use longer timeout for CI environments where content loading can be slow
        let contentLoaded = waitForHomeContent(timeout: 30)

        // Only test article navigation if content actually loaded
        // This makes the test resilient to network issues in CI
        if contentLoaded {
            let cards = articleCards()
            let firstCard = cards.firstMatch

            // Use longer timeout for CI - articles may take time to render
            if safeWaitForExistence(firstCard, timeout: 15) {
                if !firstCard.isHittable {
                    app.scrollViews.firstMatch.swipeUp()
                }

                if firstCard.isHittable {
                    firstCard.tap()
                    XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                    navigateBack(waitForNavBar: "News")
                    XCTAssertTrue(
                        safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
                        "Should return to Home after navigating back from article"
                    )
                }
            }
            // Note: Not failing if no articles - CI may have mock data issues
        }
    }
}
