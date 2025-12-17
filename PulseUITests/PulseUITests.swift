import XCTest

final class PulseUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
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
        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.exists)

        searchTab.tap()

        XCTAssertTrue(searchTab.isSelected)
    }

    func testNavigateToBookmarksTab() throws {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.exists)

        bookmarksTab.tap()

        XCTAssertTrue(bookmarksTab.isSelected)
    }

    func testNavigateToSettingsTab() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists)

        settingsTab.tap()

        XCTAssertTrue(settingsTab.isSelected)
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
