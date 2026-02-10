import XCTest

final class PulseUITests: BaseUITestCase {
    /// Tests tab bar exists, tab navigation, and settings access
    func testMainAppNavigationFlow() {
        XCTAssertTrue(app.tabBars.firstMatch.exists)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        XCTAssertTrue(homeTab.isSelected)

        // --- Bookmarks Tab ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 5), "Bookmarks tab should exist")

        bookmarksTab.tap()

        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")

        // --- Feed Tab ---
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: 5), "Feed tab should exist")

        feedTab.tap()

        XCTAssertTrue(feedTab.isSelected, "Feed tab should be selected")

        // --- Search Tab (verify exists) ---
        let searchTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")).firstMatch
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")

        // Return to Home tab for settings test
        homeTab.tap()

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
            homeTab.tap()
            wait(for: 2.0)
            let recovered = waitForHomeContent(timeout: Self.launchTimeout)
            XCTAssertTrue(recovered, "Home content should load after recovery attempt")
        }

        // Verify Home tab is ready by checking for navigation bar with longer timeout
        // The Home screen uses "News" as its navigation bar title (see Localizable.strings: "home.title" = "News")
        let homeNavBar = app.navigationBars["News"]
        let navBarReady = homeNavBar.waitForExistence(timeout: Self.launchTimeout)
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
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: Self.defaultTimeout), "Settings should open")
    }
}
