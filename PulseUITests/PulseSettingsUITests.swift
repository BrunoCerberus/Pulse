import XCTest

final class PulseSettingsUITests: BaseUITestCase {

    // MARK: - Helper Methods

    private func isSwitchOn(_ toggle: XCUIElement) -> Bool {
        if let value = toggle.value as? Bool {
            return value
        }
        if let value = toggle.value as? String {
            switch value.lowercased() {
            case "1", "on", "true":
                return true
            case "0", "off", "false":
                return false
            default:
                return false
            }
        }
        if let value = toggle.value as? NSNumber {
            return value.boolValue
        }
        return false
    }

    private func setSwitch(_ toggle: XCUIElement, to isOn: Bool) {
        if isSwitchOn(toggle) != isOn {
            toggle.tap()
        }
    }

    private func scrollContainer() -> XCUIElement? {
        let table = app.tables.firstMatch
        if table.waitForExistence(timeout: 2) {
            return table
        }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 2) {
            return scrollView
        }

        return nil
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 8) -> Bool {
        if element.exists && element.isHittable {
            return true
        }

        guard let scrollView = scrollContainer() else {
            for _ in 0..<maxSwipes {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
                if element.exists && element.isHittable {
                    return true
                }
            }
            return element.exists && element.isHittable
        }

        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable {
                return true
            }
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
        }

        return element.exists && element.isHittable
    }

    // MARK: - Navigation and Sections Tests

    /// Tests settings loads, back navigation, and all section headers exist
    func testSettingsNavigationAndSections() throws {
        navigateToSettings()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.exists)

        // Test all sections exist (scroll to find them)
        let subscriptionSection = app.staticTexts["Subscription"]
        XCTAssertTrue(subscriptionSection.waitForExistence(timeout: 5))

        let topicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(topicsSection.waitForExistence(timeout: 5))

        app.swipeUp()

        let notificationsSection = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsSection.waitForExistence(timeout: 5))

        let appearanceSection = app.staticTexts["Appearance"]
        XCTAssertTrue(appearanceSection.waitForExistence(timeout: 5))

        let contentFiltersSection = app.staticTexts["Content Filters"]
        XCTAssertTrue(contentFiltersSection.waitForExistence(timeout: 5))

        let dataSection = app.staticTexts["Data"]
        XCTAssertTrue(dataSection.waitForExistence(timeout: 5))

        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5))

        // Test back navigation
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home (Pulse)")
    }

    // MARK: - Followed Topics Tests

    /// Tests followed topics displays categories, toggle, and footer
    func testFollowedTopicsSection() throws {
        navigateToSettings()

        let topicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(topicsSection.waitForExistence(timeout: 5))

        // Category names that should appear
        let categoryNames = ["World", "Business", "Technology", "Science", "Health", "Sports", "Entertainment"]

        var foundCategory = false
        for category in categoryNames {
            let categoryLabel = app.staticTexts[category]
            let categoryButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '\(category)'")).firstMatch

            if categoryLabel.exists || categoryButton.exists {
                foundCategory = true
                break
            }
        }

        XCTAssertTrue(foundCategory, "At least one category should be displayed")

        // Test toggle functionality
        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch
        if technologyRow.exists {
            technologyRow.tap()
            Thread.sleep(forTimeInterval: 0.5)
            technologyRow.tap()
        }

        // Scroll to see footer
        app.swipeUp()

        let footerText = app.staticTexts["Articles from followed topics will appear in your For You feed."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain followed topics")
    }

    // MARK: - Notifications Tests

    /// Tests notifications toggles and dependencies
    func testNotificationsSection() throws {
        navigateToSettings()
        app.swipeUp()

        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5), "Notifications toggle should exist")

        let breakingNewsToggle = app.switches["Breaking News Alerts"]
        XCTAssertTrue(breakingNewsToggle.waitForExistence(timeout: 15), "Breaking News toggle should exist")

        // Test toggle functionality
        notificationsToggle.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Test dependency - breaking news should be disabled when notifications are off
        let notificationsEnabled = isSwitchOn(notificationsToggle)
        if !notificationsEnabled {
            XCTAssertFalse(breakingNewsToggle.isEnabled, "Breaking News should be disabled when Notifications are off")
        }
    }

    // MARK: - Appearance Tests

    /// Tests system theme and dark mode toggles
    func testAppearanceSection() throws {
        navigateToSettings()
        app.swipeUp()

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))

        // Turn off system theme to enable dark mode toggle
        let wasSystemThemeOn = isSwitchOn(systemThemeToggle)
        setSwitch(systemThemeToggle, to: false)
        if wasSystemThemeOn {
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Toggle Dark Mode
        let darkModeToggle = app.switches["Dark Mode"]
        if darkModeToggle.waitForExistence(timeout: 3) {
            darkModeToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)
            darkModeToggle.tap()
        }

        // Restore system theme
        setSwitch(systemThemeToggle, to: wasSystemThemeOn)
    }

    // MARK: - Content Filters Tests

    /// Tests muted sources and keywords disclosures
    func testContentFiltersSection() throws {
        navigateToSettings()
        app.swipeUp()

        // Look for muted sections
        let mutedSourcesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        XCTAssertTrue(mutedSourcesText.waitForExistence(timeout: 5), "Muted Sources section should exist")

        let mutedKeywordsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        XCTAssertTrue(mutedKeywordsText.waitForExistence(timeout: 5), "Muted Keywords section should exist")

        // Expand Muted Sources
        let mutedSourcesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        if mutedSourcesButton.waitForExistence(timeout: 5) {
            mutedSourcesButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let addSourceField = app.textFields["Add source..."]
            XCTAssertTrue(addSourceField.waitForExistence(timeout: 3), "Add source field should appear")
        }

        app.swipeUp()

        // Expand Muted Keywords
        let mutedKeywordsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        if mutedKeywordsButton.waitForExistence(timeout: 5) {
            mutedKeywordsButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let addKeywordField = app.textFields["Add keyword..."]
            XCTAssertTrue(addKeywordField.waitForExistence(timeout: 3), "Add keyword field should appear")
        }

        // Check footer text
        let footerText = app.staticTexts["Muted sources and keywords will be hidden from all feeds."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain content filters")
    }

    // MARK: - Data Section Tests

    /// Tests clear reading history button and confirmation
    func testDataSection() throws {
        navigateToSettings()
        app.swipeUp()
        app.swipeUp()

        let clearHistoryButton = app.buttons["Clear Reading History"]
        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5), "Clear Reading History button should exist")

        clearHistoryButton.tap()

        // Confirmation alert should appear
        let alertTitle = app.staticTexts["Clear Reading History?"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 3), "Confirmation alert should appear")

        // Check for Cancel and Clear buttons
        let cancelButton = app.buttons["Cancel"]
        let clearButton = app.buttons["Clear"]

        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button should exist")
        XCTAssertTrue(clearButton.exists, "Clear button should exist")

        // Dismiss by tapping Cancel
        cancelButton.tap()
    }

    // MARK: - Premium Section Tests

    /// Tests premium section display and paywall
    func testPremiumSection() throws {
        navigateToSettings()

        let subscriptionSection = app.staticTexts["Subscription"]
        XCTAssertTrue(subscriptionSection.waitForExistence(timeout: 10), "Subscription section should exist")

        // Premium section is at the top
        let goPremiumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'premium'")).firstMatch
        XCTAssertTrue(goPremiumText.waitForExistence(timeout: 5), "Premium section should be visible")

        // Only tap if not already premium
        let alreadyPremium = app.staticTexts["Premium Active"].exists

        if alreadyPremium {
            throw XCTSkip("User is already premium")
        }

        // Try to find and tap the premium button
        let premiumButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'Go Premium'")).firstMatch
        if premiumButton.waitForExistence(timeout: 5) {
            premiumButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Dismiss if paywall appeared
            let closeButton = app.buttons["xmark"]
            if closeButton.exists {
                closeButton.tap()
            } else {
                app.swipeDown()
            }
        }
    }

    // MARK: - About Section Tests

    /// Tests version number and GitHub link
    func testAboutSection() throws {
        navigateToSettings()
        app.swipeUp()
        app.swipeUp()

        let versionLabel = app.staticTexts["Version"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 5), "Version label should exist")

        let githubLink = app.buttons["View on GitHub"]
        XCTAssertTrue(githubLink.waitForExistence(timeout: 5), "GitHub link should exist")
    }

    // MARK: - Scroll and Layout Tests

    /// Tests settings is scrollable and uses list layout
    func testSettingsScrollAndLayout() throws {
        navigateToSettings()

        // Scroll down
        app.swipeUp()
        app.swipeUp()

        // Scroll back up
        app.swipeDown()
        app.swipeDown()

        // Settings should still be visible
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.exists, "Settings navigation should remain visible")

        // Scroll to bottom to see all sections
        for _ in 0..<5 {
            app.swipeUp()
        }

        // About section should be visible at the bottom
        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.exists, "Should be able to scroll to About section")

        // Verify list-style sections exist
        app.swipeDown()
        app.swipeDown()

        let sectionHeaders = ["Subscription", "Followed Topics", "Notifications", "Appearance"]
        var foundSections = 0
        for header in sectionHeaders {
            if app.staticTexts[header].exists {
                foundSections += 1
            }
        }

        XCTAssertGreaterThan(foundSections, 0, "Settings should have visible section headers")
    }

    // MARK: - Integration Tests

    /// Tests setting change persists across navigation
    func testSettingsChangePersists() throws {
        navigateToSettings()
        app.swipeUp()

        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5))

        let initialValue = notificationsToggle.value as? String ?? "unknown"

        // Tap to toggle
        notificationsToggle.tap()
        Thread.sleep(forTimeInterval: 1.0)

        let toggledValue = notificationsToggle.value as? String ?? "unknown"

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()

        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5))

        // Navigate back to Settings
        navigateToSettings()
        app.swipeUp()

        // Re-query the toggle element after navigation
        let notificationsToggleAfter = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggleAfter.waitForExistence(timeout: 5))

        // Verify setting persisted
        let persistedValue = notificationsToggleAfter.value as? String ?? "unknown"
        XCTAssertEqual(toggledValue, persistedValue, "Setting change should persist across navigation")

        // Restore original value
        if persistedValue != initialValue {
            notificationsToggleAfter.tap()
        }
    }
}
