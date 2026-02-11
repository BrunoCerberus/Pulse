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

        waitForHomeContent(timeout: Self.launchTimeout)

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
