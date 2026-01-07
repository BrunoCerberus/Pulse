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

    /// Wait for source selection view (post-onboarding state)
    private func waitForSourceSelectionView(timeout: TimeInterval = 8) -> Bool {
        sourceChipsScrollView().waitForExistence(timeout: timeout)
    }

    private let sourceNames = ["Bookmarks", "Reading History", "Fresh News"]

    // MARK: - Navigation Test

    /// Tests basic digest tab navigation
    func testDigestTabNavigation() throws {
        let digestTab = app.tabBars.buttons["Digest"]
        XCTAssertTrue(digestTab.exists, "Digest tab should exist")

        navigateToDigestTab()

        XCTAssertTrue(digestTab.isSelected, "Digest tab should be selected")

        let navTitle = app.navigationBars["Digest"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Digest' should exist")
    }

    /// Tests onboarding state displays sources
    func testOnboardingShowsSources() throws {
        navigateToDigestTab()

        // Check for source options
        var foundSource = false
        for source in sourceNames {
            if sourceExists(source) {
                foundSource = true
                break
            }
        }
        XCTAssertTrue(foundSource, "Onboarding should show source options")
    }

    /// Tests source selection transitions from onboarding
    func testSourceSelectionTransition() throws {
        navigateToDigestTab()

        // Select a source
        XCTAssertTrue(selectSource("Bookmarks"), "Should be able to select Bookmarks source")

        // Wait for UI to settle after selection
        wait(for: 2.0)

        // After selection, "Select a Source" header should no longer be visible
        // or source chips should appear
        let selectSourceText = app.staticTexts["Select a Source"]
        let sourceChips = sourceChipsScrollView()

        // Either chips appear OR the onboarding prompt is gone
        let transitioned = sourceChips.exists || !selectSourceText.exists
        XCTAssertTrue(transitioned, "Should transition from onboarding after selecting a source")
    }

    /// Tests source chip horizontal scrolling
    func testSourceChipsScrolling() throws {
        navigateToDigestTab()

        // Select a source to get to the chips view
        if selectSource(sourceNames.first!) {
            let scrollView = sourceChipsScrollView()
            if scrollView.waitForExistence(timeout: Self.defaultTimeout) {
                // Test horizontal scrolling
                scrollView.swipeLeft()
                scrollView.swipeRight()

                // Verify chips still visible
                var foundSource = false
                for source in sourceNames {
                    if sourceExists(source) {
                        foundSource = true
                        break
                    }
                }
                XCTAssertTrue(foundSource, "Source chips should be visible after scrolling")
            }
        }
    }

    /// Tests navigation to settings from no topics state
    func testNoTopicsConfigureNavigation() throws {
        navigateToDigestTab()

        // Select Fresh News which may show no topics state
        if selectSource("Fresh News") {
            let configureButton = app.buttons["Configure Topics"]
            if configureButton.waitForExistence(timeout: Self.defaultTimeout) {
                configureButton.tap()

                // Should navigate to settings
                let settingsNav = app.navigationBars["Settings"]
                XCTAssertTrue(
                    settingsNav.waitForExistence(timeout: Self.defaultTimeout),
                    "Should navigate to Settings from Configure Topics"
                )
            }
        }
    }

    /// Tests tab switching preserves state
    func testTabSwitching() throws {
        navigateToDigestTab()

        // Select a source
        XCTAssertTrue(selectSource("Bookmarks"), "Should select Bookmarks source")

        // Wait for transition
        _ = waitForSourceSelectionView(timeout: Self.defaultTimeout)

        // Switch to Home
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.shortTimeout), "Home should load after tab switch")

        // Switch back to Digest
        navigateToDigestTab()

        let digestNav = app.navigationBars["Digest"]
        XCTAssertTrue(digestNav.waitForExistence(timeout: Self.shortTimeout), "Digest should load after tab switch")
    }

    /// Tests content appears after source selection
    func testContentAfterSourceSelection() throws {
        navigateToDigestTab()

        // Select Fresh News source (triggers article loading)
        if selectSource("Fresh News") {
            // Wait for any content state to appear
            wait(for: 2.0)

            // Check for any valid content state:
            // - Source chips (source selection view)
            // - No Topics message (user hasn't configured topics)
            // - No Articles message (empty state)
            // - Generate button (articles available)
            // - Loading indicator
            let sourceChips = sourceChipsScrollView()
            let noTopicsText = app.staticTexts["No Topics Selected"]
            let noArticlesText = app.staticTexts["No Articles"]
            let generateButton = app.buttons["generateDigestButton"]
            let configureButton = app.buttons["Configure Topics"]

            let hasContent = sourceChips.exists ||
                            noTopicsText.exists ||
                            noArticlesText.exists ||
                            generateButton.exists ||
                            configureButton.exists

            XCTAssertTrue(hasContent, "Should show content after selecting a source")
        }
    }
}
