import XCTest

final class PulseSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSettingsViewLoads() throws {
        app.tabBars.buttons["Settings"].tap()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: 5))
    }

    func testFollowedTopicsSectionExists() throws {
        app.tabBars.buttons["Settings"].tap()

        let topicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(topicsSection.waitForExistence(timeout: 5))
    }

    func testNotificationsSectionExists() throws {
        app.tabBars.buttons["Settings"].tap()

        let notificationsSection = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsSection.waitForExistence(timeout: 5))
    }

    func testAppearanceSectionExists() throws {
        app.tabBars.buttons["Settings"].tap()

        let appearanceSection = app.staticTexts["Appearance"]
        XCTAssertTrue(appearanceSection.waitForExistence(timeout: 5))
    }

    func testDarkModeToggleExists() throws {
        app.tabBars.buttons["Settings"].tap()

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))
    }

    func testAboutSectionExists() throws {
        app.tabBars.buttons["Settings"].tap()

        app.swipeUp()

        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5))
    }
}
