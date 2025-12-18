import XCTest

final class PulseUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchEnvironment["XCTestConfigurationFilePath"] = "UI"
        app.launch()

        // Wait for app to be fully running and splash screen to complete
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        // Wait for tab bar to appear (indicates splash screen is done)
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should appear after splash screen")
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    func testTabBarExists() throws {
        XCTAssertTrue(app.tabBars.element.exists)
    }

    func testHomeTabIsSelected() throws {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        XCTAssertTrue(homeTab.isSelected)
    }

    func testNavigateToSearchTab() throws {
        // Search tab uses role: .search which may have special accessibility handling
        // Try multiple identifiers that could match the search tab
        let searchTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")).firstMatch
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")

        searchTab.tap()

        // Verify navigation to search by checking for search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should appear after tapping Search tab")
    }

    func testNavigateToBookmarksTab() throws {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.exists)

        bookmarksTab.tap()

        XCTAssertTrue(bookmarksTab.isSelected)
    }

    func testNavigateToSettingsViaGearButton() throws {
        // Settings is accessed via the gear button in Home navigation bar, not a tab
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist")

        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings should open")
    }

    func testNavigateToCategoriesTab() throws {
        let categoriesTab = app.tabBars.buttons["Categories"]
        XCTAssertTrue(categoriesTab.exists)

        categoriesTab.tap()

        XCTAssertTrue(categoriesTab.isSelected)
    }

    func testNavigateToForYouTab() throws {
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists)

        forYouTab.tap()

        XCTAssertTrue(forYouTab.isSelected)
    }
}
