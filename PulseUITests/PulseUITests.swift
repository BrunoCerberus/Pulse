import XCTest

final class PulseUITests: BaseUITestCase {

    /// Tests tab bar exists, tab navigation, and settings access
    func testMainAppNavigationFlow() throws {
        XCTAssertTrue(app.tabBars.firstMatch.exists)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        XCTAssertTrue(homeTab.isSelected)

        // --- For You Tab ---
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: 5), "For You tab should exist")

        forYouTab.tap()

        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")

        // --- Bookmarks Tab ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 5), "Bookmarks tab should exist")

        bookmarksTab.tap()

        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")

        // --- Search Tab (verify exists) ---
        let searchTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")).firstMatch
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")

        // Return to Home tab for settings test
        homeTab.tap()

        let homeNavBar = app.navigationBars["News"]
        let gearButton = app.navigationBars.buttons["gearshape"]
        let homeLoaded = homeNavBar.waitForExistence(timeout: Self.defaultTimeout) || gearButton.waitForExistence(timeout: 2)
        XCTAssertTrue(homeLoaded, "Home navigation bar should exist")

        // Settings is accessed via the gear button in Home navigation bar, not a tab
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist")

        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings should open")
    }
}
