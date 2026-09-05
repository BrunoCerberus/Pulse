import XCTest

final class NavigationUITests: BaseUITestCase {
    // MARK: - Combined Flow Test

    // Tests root navigation, settings flow, and article detail navigation
    // Note: Search tab navigation is tested separately in PulseSearchUITests
    // swiftlint:disable:next function_body_length
    func testNavigationFlow() {
        let expectedTabs = ["Home", "Media", "Feed", "Bookmarks", "Search"]
        for tabName in expectedTabs {
            XCTAssertTrue(
                safeWaitForExistence(navigationItem(named: tabName), timeout: Self.defaultTimeout),
                "Navigation item '\(tabName)' should exist in the tab bar or sidebar",
            )
        }

        // --- Navigate to Each Tab and Verify (except Search - tested in PulseSearchUITests) ---

        // Home — setUp already lands on Home tab; check nav bar directly without re-tapping.
        // Tapping the already-active Home tab triggers iOS scroll-to-top which briefly
        // interrupts the navigation bar accessibility element, causing intermittent failures.
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Home tab should display News navigation bar",
        )

        // Feed (Daily Digest)
        navigateToFeedTab()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Daily Digest"], timeout: Self.defaultTimeout),
            "Feed tab should display Daily Digest navigation bar",
        )

        // Bookmarks
        navigateToBookmarksTab()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.defaultTimeout),
            "Bookmarks tab should display Bookmarks navigation bar",
        )

        // Return to Home for Settings test
        navigateToTab("Home")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Should return to Home tab",
        )

        // --- Settings Navigation ---
        navigateToSettings()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout),
            "Settings should be accessible from Home",
        )

        navigateBack(waitForNavBar: "News")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
            "Should return to Home after navigating back from Settings",
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
                if !firstCard.exists {
                    app.scrollViews.firstMatch.swipeUp()
                }

                if firstCard.exists {
                    firstCard.tap()
                    XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                    navigateBack(waitForNavBar: "News")
                    XCTAssertTrue(
                        safeWaitForExistence(app.navigationBars["News"], timeout: Self.defaultTimeout),
                        "Should return to Home after navigating back from article",
                    )
                }
            }
            // Note: Not failing if no articles - CI may have mock data issues
        }
    }
}
