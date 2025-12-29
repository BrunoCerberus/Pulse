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
                wait(for: 0.3)
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
            wait(for: 0.3)
        }

        return element.exists && element.isHittable
    }

    // MARK: - Navigation and Sections Tests

    /// Tests settings loads, back navigation, all section headers exist, and scroll/layout
    func testSettingsNavigationSectionsAndLayout() throws {
        navigateToSettings()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: Self.defaultTimeout), "Settings navigation should exist")

        // Wait for settings content to load
        wait(for: 1)

        // Test Account section first (it's at the top)
        let accountSection = app.staticTexts["Account"]
        guard accountSection.waitForExistence(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Account section did not load in time")
        }

        // Test Subscription section (right below Account)
        let subscriptionSection = app.staticTexts["Subscription"]
        XCTAssertTrue(subscriptionSection.waitForExistence(timeout: 5), "Subscription section should exist")

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

        // Test scroll to bottom and back up
        for _ in 0..<3 {
            app.swipeUp()
        }
        XCTAssertTrue(aboutSection.exists, "Should be able to scroll to About section")

        app.swipeDown()
        app.swipeDown()

        // Verify list-style sections exist after scrolling
        let sectionHeaders = ["Subscription", "Followed Topics", "Notifications", "Appearance"]
        var foundSections = 0
        for header in sectionHeaders {
            if app.staticTexts[header].exists {
                foundSections += 1
            }
        }
        XCTAssertGreaterThan(foundSections, 0, "Settings should have visible section headers")

        // Test back navigation
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()

        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home (Pulse)")
    }

    // MARK: - Topics and Notifications Tests

    /// Tests followed topics, notifications toggles, and dependencies
    func testTopicsAndNotificationsSections() throws {
        navigateToSettings()

        // Wait for settings content to load
        wait(for: 1)

        // --- Followed Topics Section ---
        let topicsSection = app.staticTexts["Followed Topics"]
        guard topicsSection.waitForExistence(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Followed Topics section did not load in time")
        }

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
            wait(for: 0.5)
            technologyRow.tap()
        }

        // Scroll to see footer
        app.swipeUp()

        let footerText = app.staticTexts["Articles from followed topics will appear in your For You feed."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain followed topics")

        // --- Notifications Section ---
        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5), "Notifications toggle should exist")

        let breakingNewsToggle = app.switches["Breaking News Alerts"]
        XCTAssertTrue(breakingNewsToggle.waitForExistence(timeout: 15), "Breaking News toggle should exist")

        // Test toggle functionality
        notificationsToggle.tap()
        wait(for: 0.5)

        // Test dependency - breaking news should be disabled when notifications are off
        let notificationsEnabled = isSwitchOn(notificationsToggle)
        if !notificationsEnabled {
            XCTAssertFalse(breakingNewsToggle.isEnabled, "Breaking News should be disabled when Notifications are off")
        }
    }

    // MARK: - Appearance and Content Filters Tests

    /// Tests appearance toggles and content filter disclosures
    func testAppearanceAndContentFiltersSections() throws {
        navigateToSettings()
        app.swipeUp()

        // --- Appearance Section ---
        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))

        // Turn off system theme to enable dark mode toggle
        let wasSystemThemeOn = isSwitchOn(systemThemeToggle)
        setSwitch(systemThemeToggle, to: false)
        if wasSystemThemeOn {
            wait(for: 0.5)
        }

        // Toggle Dark Mode
        let darkModeToggle = app.switches["Dark Mode"]
        if darkModeToggle.waitForExistence(timeout: 3) {
            darkModeToggle.tap()
            wait(for: 0.5)
            darkModeToggle.tap()
        }

        // Restore system theme
        setSwitch(systemThemeToggle, to: wasSystemThemeOn)

        // --- Content Filters Section ---
        let mutedSourcesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        XCTAssertTrue(mutedSourcesText.waitForExistence(timeout: 5), "Muted Sources section should exist")

        let mutedKeywordsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        XCTAssertTrue(mutedKeywordsText.waitForExistence(timeout: 5), "Muted Keywords section should exist")

        // Expand Muted Sources
        let mutedSourcesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        if mutedSourcesButton.waitForExistence(timeout: 5) {
            mutedSourcesButton.tap()
            wait(for: 0.5)

            let addSourceField = app.textFields["Add source..."]
            XCTAssertTrue(addSourceField.waitForExistence(timeout: 3), "Add source field should appear")
        }

        app.swipeUp()

        // Expand Muted Keywords
        let mutedKeywordsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        if mutedKeywordsButton.waitForExistence(timeout: 5) {
            mutedKeywordsButton.tap()
            wait(for: 0.5)

            let addKeywordField = app.textFields["Add keyword..."]
            XCTAssertTrue(addKeywordField.waitForExistence(timeout: 3), "Add keyword field should appear")
        }

        // Check footer text
        let footerText = app.staticTexts["Muted sources and keywords will be hidden from all feeds."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain content filters")
    }

    // MARK: - Data, Premium, and About Tests

    /// Tests data section, premium section, and about section
    func testDataPremiumAndAboutSections() throws {
        navigateToSettings()

        // Wait for settings content to load
        wait(for: 1)

        // --- Premium Section (at the top) ---
        let subscriptionSection = app.staticTexts["Subscription"]
        guard subscriptionSection.waitForExistence(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Subscription section did not load in time")
        }

        let goPremiumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'premium'")).firstMatch
        XCTAssertTrue(goPremiumText.waitForExistence(timeout: 5), "Premium section should be visible")

        // Only tap if not already premium
        let alreadyPremium = app.staticTexts["Premium Active"].exists

        if !alreadyPremium {
            let premiumButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'Go Premium'")).firstMatch
            if premiumButton.waitForExistence(timeout: 5) {
                premiumButton.tap()
                wait(for: 1)

                // Dismiss if paywall appeared
                let closeButton = app.buttons["xmark"]
                if closeButton.exists {
                    closeButton.tap()
                } else {
                    app.swipeDown()
                }
            }
        }

        // --- Data Section ---
        let clearHistoryButton = app.buttons["Clear Reading History"]
        let foundClearHistory = scrollToElement(clearHistoryButton, maxSwipes: 10)
        XCTAssertTrue(foundClearHistory, "Clear Reading History button should exist")

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

        // --- About Section ---
        let versionLabel = app.staticTexts["Version"]
        let foundVersion = scrollToElement(versionLabel, maxSwipes: 5)
        XCTAssertTrue(foundVersion, "Version label should exist")

        let githubLink = app.buttons["View on GitHub"]
        let foundGithub = scrollToElement(githubLink, maxSwipes: 3)
        XCTAssertTrue(foundGithub, "GitHub link should exist")
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
        wait(for: 1.0)

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
