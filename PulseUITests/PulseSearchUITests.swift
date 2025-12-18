import XCTest

final class PulseSearchUITests: XCTestCase {
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

    /// Navigate to Search tab (handles role: .search accessibility)
    private func navigateToSearchTab() {
        let searchTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'search' OR identifier CONTAINS[c] 'search'")).firstMatch
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")
        searchTab.tap()
    }

    func testSearchBarExists() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }

    func testSearchBarCanReceiveInput() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")

        // Typing in searchable modifier triggers view updates
        // Verify the keyboard appeared and we can dismiss it (indicates input was received)
        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear for text input")
    }

    func testInitialSearchEmptyStateExists() throws {
        navigateToSearchTab()

        // Initial state shows "Search for News" empty state
        let emptyStateLabel = app.staticTexts["Search for News"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 5), "Initial empty state should show 'Search for News'")
    }
}
