import XCTest

final class PulseSettingsUITests: XCTestCase {
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

    // MARK: - Helper Methods

    /// Navigate to Settings via the gear button in Home navigation bar
    private func navigateToSettings() {
        // Ensure we're on Home tab first
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        }

        // Tap the gear button in the navigation bar
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Gear button should exist in navigation bar")
        gearButton.tap()

        // Wait for Settings view to appear
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings navigation bar should appear")
    }

    func testSettingsViewLoads() throws {
        navigateToSettings()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.exists)
    }

    func testFollowedTopicsSectionExists() throws {
        navigateToSettings()

        let topicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(topicsSection.waitForExistence(timeout: 5))
    }

    func testNotificationsSectionExists() throws {
        navigateToSettings()

        let notificationsSection = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsSection.waitForExistence(timeout: 5))
    }

    func testAppearanceSectionExists() throws {
        navigateToSettings()

        let appearanceSection = app.staticTexts["Appearance"]
        XCTAssertTrue(appearanceSection.waitForExistence(timeout: 5))
    }

    func testDarkModeToggleExists() throws {
        navigateToSettings()

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))
    }

    func testAboutSectionExists() throws {
        navigateToSettings()

        app.swipeUp()

        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5))
    }
}
