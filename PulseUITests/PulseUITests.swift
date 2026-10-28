import XCTest

final class PulseUITests: BaseUITestCase {
    /// Tests root navigation exists, tab navigation, and settings access
    func testMainAppNavigationFlow() {
        XCTAssertTrue(
            rootNavigationElements().contains { safeExists($0) },
            "Tab bar or sidebar should exist",
        )
        XCTAssertTrue(waitForActiveTab("Home"), "Home should be the active tab")

        // --- Bookmarks Tab ---
        XCTAssertTrue(
            safeWaitForExistence(navigationItem(named: "Bookmarks"), timeout: 5),
            "Bookmarks tab should exist",
        )
        navigateToBookmarksTab()
        XCTAssertTrue(waitForActiveTab("Bookmarks"), "Bookmarks tab should be selected")

        // --- Feed Tab ---
        XCTAssertTrue(safeWaitForExistence(navigationItem(named: "Feed"), timeout: 5), "Feed tab should exist")
        navigateToFeedTab()
        XCTAssertTrue(waitForActiveTab("Feed"), "Feed tab should be selected")

        // --- Search Tab (verify exists) ---
        XCTAssertTrue(safeWaitForExistence(navigationItem(named: "Search"), timeout: 5), "Search tab should exist")

        // Return to Home tab for settings test
        navigateToTab("Home")

        // Allow UI to fully settle after multi-tab navigation.
        // CI simulators need extra time to re-render the Home tab's NavigationStack.
        wait(for: 1.0)

        // Wait for Home content with a longer timeout for CI.
        // After navigating through multiple tabs, the Home view's accessibility tree
        // can take significantly longer to populate on shared CI runners.
        // Use a recovery approach instead of hard assertion to prevent crashes.
        let contentLoaded = waitForHomeContent(timeout: Self.launchTimeout)
        if !contentLoaded {
            // Recovery: try tapping Home tab again and wait longer
            navigateToTab("Home")
            wait(for: 2.0)
            let recovered = waitForHomeContent(timeout: Self.launchTimeout)
            XCTAssertTrue(recovered, "Home content should load after recovery attempt")
        }

        // Verify Home tab is ready by checking for navigation bar with longer timeout
        // The Home screen uses "News" as its navigation bar title (see Localizable.strings: "home.title" = "News")
        let homeNavBar = app.navigationBars["News"]
        let navBarReady = safeWaitForExistence(homeNavBar, timeout: Self.launchTimeout)
        XCTAssertTrue(navBarReady, "Home navigation bar ('News') should exist")

        // Find the gear button using both system image name and accessibility label.
        // On iOS 26+, the button may be identified by its accessibilityLabel ("Settings")
        // rather than its system image name ("gearshape").
        let gearButton = app.navigationBars.buttons["gearshape"]
        let settingsButton = app.navigationBars.buttons["Settings"]
        let gearFound = waitForAny([gearButton, settingsButton], timeout: Self.launchTimeout)
        XCTAssertTrue(gearFound, "Gear/Settings button should exist in navigation bar")

        let buttonToTap = gearButton.exists ? gearButton : settingsButton
        buttonToTap.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(safeWaitForExistence(settingsNavBar, timeout: Self.defaultTimeout), "Settings should open")
    }
}
