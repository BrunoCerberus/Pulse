import XCTest

final class DigestUITests: BaseUITestCase {

    // MARK: - Helper Methods

    private func sourceChipsScrollView() -> XCUIElement {
        app.scrollViews["digestSourceChipsScrollView"]
    }

    /// Finds and taps a source button by name
    /// Handles both card labels (with descriptions) and chip labels (just name)
    private func selectSource(_ source: String) -> Bool {
        // First try exact match (chips)
        let exactButton = app.buttons[source]
        if exactButton.waitForExistence(timeout: Self.shortTimeout), exactButton.isHittable {
            exactButton.tap()
            return true
        }

        // Try BEGINSWITH match (cards have "Source. Description" format)
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", source)
        let matchingButton = app.buttons.matching(predicate).firstMatch
        if matchingButton.waitForExistence(timeout: Self.shortTimeout), matchingButton.isHittable {
            matchingButton.tap()
            return true
        }

        return false
    }

    /// Check if a source element exists (button or text)
    private func sourceExists(_ source: String) -> Bool {
        // Check exact match
        if app.buttons[source].exists || app.staticTexts[source].exists {
            return true
        }
        // Check BEGINSWITH match
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", source)
        return app.buttons.matching(predicate).count > 0 ||
               app.staticTexts.matching(predicate).count > 0
    }

    private let sourceNames = ["Bookmarks", "Reading History", "Fresh News"]

    // MARK: - Combined Flow Test

    /// Tests digest navigation, source selection, content states, and tab switching
    func testDigestFlow() throws {
        // --- Navigation ---
        let digestTab = app.tabBars.buttons["Digest"]
        XCTAssertTrue(digestTab.exists, "Digest tab should exist")

        navigateToDigestTab()

        XCTAssertTrue(digestTab.isSelected, "Digest tab should be selected")

        let navTitle = app.navigationBars["Digest"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Digest' should exist")

        // --- Onboarding State ---
        var foundSource = false
        for source in sourceNames {
            if sourceExists(source) {
                foundSource = true
                break
            }
        }
        XCTAssertTrue(foundSource, "Onboarding should show source options")

        // --- Source Selection ---
        let sourceTapped = selectSource("Bookmarks")
        XCTAssertTrue(sourceTapped, "Should be able to select Bookmarks source")

        if sourceTapped {
            // Wait for UI to settle
            wait(for: 2.0)

            // After selection, should transition from onboarding
            let selectSourceText = app.staticTexts["Select a Source"]
            let sourceChips = sourceChipsScrollView()

            let transitioned = sourceChips.exists || !selectSourceText.exists
            XCTAssertTrue(transitioned, "Should transition from onboarding after selecting a source")

            // --- Content States ---
            let noTopicsText = app.staticTexts["No Topics Selected"]
            let noArticlesText = app.staticTexts["No Articles"]
            let generateButton = app.buttons["generateDigestButton"]
            let configureButton = app.buttons["Configure Topics"]

            // --- Source Chips Scrolling ---
            if sourceChips.exists {
                sourceChips.swipeLeft()
                sourceChips.swipeRight()

                foundSource = false
                for source in sourceNames {
                    if sourceExists(source) {
                        foundSource = true
                        break
                    }
                }
                XCTAssertTrue(foundSource, "Source chips should be visible after scrolling")
            }

            // --- Configure Topics Navigation (if available) ---
            if configureButton.exists {
                configureButton.tap()

                let settingsNav = app.navigationBars["Settings"]
                XCTAssertTrue(
                    settingsNav.waitForExistence(timeout: Self.defaultTimeout),
                    "Should navigate to Settings from Configure Topics"
                )

                // Navigate back to Digest
                navigateBack()
                _ = navTitle.waitForExistence(timeout: Self.shortTimeout)
            }
        }

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.shortTimeout), "Home should load after tab switch")

        navigateToDigestTab()

        let navTitleAfterSwitch = app.navigationBars["Digest"]
        XCTAssertTrue(navTitleAfterSwitch.waitForExistence(timeout: Self.shortTimeout), "Digest view should load after tab switch")
    }
}
