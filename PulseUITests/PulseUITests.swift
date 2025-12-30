import XCTest

final class PulseUITests: BaseUITestCase {

    /// Tests tab bar exists, tab navigation, and settings access
    func testMainAppNavigationFlow() throws {
        XCTAssertTrue(app.tabBars.firstMatch.exists)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        XCTAssertTrue(homeTab.isSelected)

        // --- Bookmarks Tab ---
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 5), "Bookmarks tab should exist")

        bookmarksTab.tap()

        XCTAssertTrue(bookmarksTab.isSelected, "Bookmarks tab should be selected")

        // --- Categories Tab ---
        let categoriesTab = app.tabBars.buttons["Categories"]
        XCTAssertTrue(categoriesTab.waitForExistence(timeout: 5), "Categories tab should exist")

        categoriesTab.tap()

        XCTAssertTrue(categoriesTab.isSelected, "Categories tab should be selected")

        // --- For You Tab ---
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: 5), "For You tab should exist")

        forYouTab.tap()

        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")

        // --- Search Tab (last, as it has liquid glass style that may affect tab bar) ---
        let searchTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")).firstMatch
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")

        searchTab.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should appear after tapping Search tab")

        // Return to Home before opening Settings
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            wait(for: 0.5)
        }

        resetToHomeTab()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Home navigation bar should exist")

        // Settings is accessed via the gear button in Home navigation bar, not a tab
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist")

        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings should open")
    }
}
