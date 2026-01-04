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

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 5) -> Bool {
        if element.exists, element.isHittable { return true }

        // Try table first (Settings uses List which renders as UITableView), then scrollViews
        let container: XCUIElement
        if app.tables.firstMatch.exists {
            container = app.tables.firstMatch
        } else if app.scrollViews.firstMatch.exists {
            container = app.scrollViews.firstMatch
        } else {
            // Fallback to swiping on app itself
            for _ in 0..<maxSwipes {
                app.swipeUp()
                if element.exists, element.isHittable { return true }
            }
            return element.exists && element.isHittable
        }

        for _ in 0..<maxSwipes {
            container.swipeUp()
            if element.waitForExistence(timeout: 0.1), element.isHittable { return true }
        }
        return element.exists && element.isHittable
    }

    // MARK: - Combined Flow Test

    /// Tests settings sections, toggles, content filters, and persistence
    func testSettingsFlow() throws {
        navigateToSettings()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: Self.defaultTimeout), "Settings navigation should exist")

        let accountSection = app.staticTexts["Account"]
        XCTAssertTrue(accountSection.waitForExistence(timeout: Self.defaultTimeout), "Account section should exist")

        let subscriptionSection = app.staticTexts["Subscription"]
        XCTAssertTrue(subscriptionSection.waitForExistence(timeout: 5), "Subscription section should exist")

        let topicsSection = app.staticTexts["Followed Topics"]
        XCTAssertTrue(topicsSection.waitForExistence(timeout: 5), "Followed Topics section should exist")

        let goPremiumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'premium'")).firstMatch
        XCTAssertTrue(goPremiumText.waitForExistence(timeout: 5), "Premium section should be visible")

        let sectionHeaders = ["Subscription", "Followed Topics", "Notifications", "Appearance"]
        var foundSections = 0
        for header in sectionHeaders {
            if app.staticTexts[header].exists {
                foundSections += 1
            }
        }
        XCTAssertGreaterThan(foundSections, 0, "Settings should have visible section headers")

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

        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch
        if technologyRow.exists {
            technologyRow.tap()
            technologyRow.tap()
        }

        app.swipeUp()

        let topicsFooterText = app.staticTexts["Articles from followed topics will appear in your For You feed."]
        XCTAssertTrue(topicsFooterText.waitForExistence(timeout: 5), "Footer text should explain followed topics")

        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5), "Notifications toggle should exist")

        let breakingNewsToggle = app.switches["Breaking News Alerts"]
        XCTAssertTrue(breakingNewsToggle.waitForExistence(timeout: 5), "Breaking News toggle should exist")

        let initialNotificationsEnabled = isSwitchOn(notificationsToggle)
        notificationsToggle.tap()

        let notificationsEnabledAfter = isSwitchOn(notificationsToggle)
        if !notificationsEnabledAfter {
            XCTAssertFalse(breakingNewsToggle.isEnabled, "Breaking News should be disabled when Notifications are off")
        }

        setSwitch(notificationsToggle, to: initialNotificationsEnabled)

        // --- Persistence Check ---
        let persistInitialValue = isSwitchOn(notificationsToggle)
        notificationsToggle.tap()

        let toggledValue = isSwitchOn(notificationsToggle)

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Should return to Home")

        navigateToSettings()

        let notificationsToggleAfter = app.switches["Enable Notifications"]
        XCTAssertTrue(scrollToElement(notificationsToggleAfter), "Notifications toggle should exist")

        let persistedValue = isSwitchOn(notificationsToggleAfter)
        XCTAssertEqual(toggledValue, persistedValue, "Setting change should persist across navigation")

        if persistedValue != persistInitialValue {
            notificationsToggleAfter.tap()
        }

        // --- Appearance Section ---
        let appearanceSection = app.staticTexts["Appearance"]
        XCTAssertTrue(scrollToElement(appearanceSection), "Appearance section should exist")

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))

        let wasSystemThemeOn = isSwitchOn(systemThemeToggle)
        setSwitch(systemThemeToggle, to: false)

        let darkModeToggle = app.switches["Dark Mode"]
        if darkModeToggle.waitForExistence(timeout: 2) {
            darkModeToggle.tap()
            darkModeToggle.tap()
        }

        setSwitch(systemThemeToggle, to: wasSystemThemeOn)

        // --- Content Filters Section ---
        let mutedSourcesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        XCTAssertTrue(scrollToElement(mutedSourcesText), "Muted Sources section should exist")

        let mutedKeywordsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        XCTAssertTrue(scrollToElement(mutedKeywordsText), "Muted Keywords section should exist")

        let mutedSourcesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        if mutedSourcesButton.waitForExistence(timeout: 3) {
            mutedSourcesButton.tap()
            let addSourceField = app.textFields["Add source..."]
            XCTAssertTrue(addSourceField.waitForExistence(timeout: 2), "Add source field should appear")
        }

        app.swipeUp()

        let mutedKeywordsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        if mutedKeywordsButton.waitForExistence(timeout: 3) {
            mutedKeywordsButton.tap()
            let addKeywordField = app.textFields["Add keyword..."]
            XCTAssertTrue(addKeywordField.waitForExistence(timeout: 2), "Add keyword field should appear")
        }

        let contentFiltersFooter = app.staticTexts["Muted sources and keywords will be hidden from all feeds."]
        XCTAssertTrue(contentFiltersFooter.waitForExistence(timeout: 5), "Footer text should explain content filters")

        // --- Data and About Sections ---
        let dataSection = app.staticTexts["Data"]
        XCTAssertTrue(scrollToElement(dataSection), "Data section should exist")

        let clearHistoryButton = app.buttons["clearReadingHistoryButton"]
        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5), "Clear Reading History button should exist")

        clearHistoryButton.tap()

        let alertTitle = app.staticTexts["Clear Reading History"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 3), "Confirmation alert should appear")

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button should exist")
        cancelButton.tap()

        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(scrollToElement(aboutSection), "About section should exist")

        let versionLabel = app.staticTexts["Version"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 5), "Version label should exist")

        let githubLink = app.buttons["View on GitHub"]
        XCTAssertTrue(githubLink.waitForExistence(timeout: 5), "GitHub link should exist")
    }
}
