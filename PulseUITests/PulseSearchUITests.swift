import XCTest

final class PulseSearchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSearchBarExists() throws {
        app.tabBars.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }

    func testSearchBarCanReceiveInput() throws {
        app.tabBars.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")

        XCTAssertTrue(searchField.value as? String == "technology")
    }

    func testCategorySuggestionsExist() throws {
        app.tabBars.buttons["Search"].tap()

        let trendingSection = app.staticTexts["Trending Topics"]
        XCTAssertTrue(trendingSection.waitForExistence(timeout: 5))
    }
}
