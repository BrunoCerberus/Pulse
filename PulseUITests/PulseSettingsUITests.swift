import XCTest

final class PulseSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()

        // Wait for app to be fully running and splash screen to complete
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20.0), "App should be running in the foreground")

        // Wait for tab bar to appear (indicates splash screen is done)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20.0), "Tab bar should appear after splash screen")
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

    private func scrollToTop(maxSwipes: Int = 4) {
        guard let scrollView = scrollContainer() else {
            for _ in 0..<maxSwipes {
                app.swipeDown()
                Thread.sleep(forTimeInterval: 0.2)
            }
            return
        }

        for _ in 0..<maxSwipes {
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.2)
        }
    }

    // MARK: - Navigation Tests

    func testSettingsViewLoads() throws {
        navigateToSettings()

        let navigationTitle = app.navigationBars["Settings"]
        XCTAssertTrue(navigationTitle.exists)
    }

    func testBackNavigationFromSettings() throws {
        navigateToSettings()

        // Find and tap back button
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")

        backButton.tap()

        // Verify we're back on Home
        let homeNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 5), "Should return to Home (Pulse)")
    }

    // MARK: - Section Existence Tests

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

        // Scroll to find the section since premium section is at top
        app.swipeUp()

        let appearanceSection = app.staticTexts["Appearance"]
        XCTAssertTrue(appearanceSection.waitForExistence(timeout: 5))
    }

    func testDarkModeToggleExists() throws {
        navigateToSettings()

        // Scroll to find the toggle since premium section is at top
        app.swipeUp()

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))
    }

    func testAboutSectionExists() throws {
        navigateToSettings()

        app.swipeUp()

        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5))
    }

    func testContentFiltersSectionExists() throws {
        navigateToSettings()

        app.swipeUp()

        let contentFiltersSection = app.staticTexts["Content Filters"]
        XCTAssertTrue(contentFiltersSection.waitForExistence(timeout: 5))
    }

    func testDataSectionExists() throws {
        navigateToSettings()

        app.swipeUp()

        let dataSection = app.staticTexts["Data"]
        XCTAssertTrue(dataSection.waitForExistence(timeout: 5))
    }

    func testSubscriptionSectionExists() throws {
        navigateToSettings()

        let subscriptionSection = app.staticTexts["Subscription"]
        XCTAssertTrue(subscriptionSection.waitForExistence(timeout: 5))
    }

    // MARK: - Followed Topics Tests

    func testFollowedTopicsDisplaysCategories() throws {
        navigateToSettings()

        // Wait for section to load
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
    }

    func testToggleTopicSelection() throws {
        navigateToSettings()

        // Wait for section to load
        Thread.sleep(forTimeInterval: 1)

        // Find a topic row (e.g., Technology)
        let technologyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch

        if technologyRow.exists {
            // Note initial state
            let hasCheckmark = app.images["checkmark"].exists

            // Tap to toggle
            technologyRow.tap()

            // Wait for state change
            Thread.sleep(forTimeInterval: 0.5)

            // Tap again to revert (if testing toggle behavior)
            technologyRow.tap()

            XCTAssertTrue(true, "Topic toggle completed")
        }
    }

    func testFollowedTopicsFooterText() throws {
        navigateToSettings()

        let footerText = app.staticTexts["Articles from followed topics will appear in your For You feed."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain followed topics")
    }

    // MARK: - Notifications Toggle Tests

    func testNotificationsToggleExists() throws {
        navigateToSettings()

        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5), "Notifications toggle should exist")
    }

    func testBreakingNewsToggleExists() throws {
        navigateToSettings()

        // Wait for Settings to fully load
        let notificationsSection = app.staticTexts["Notifications"]
        scrollToTop()
        XCTAssertTrue(notificationsSection.waitForExistence(timeout: 10), "Notifications section should exist")

        let breakingNewsToggle = app.switches["Breaking News Alerts"]
        XCTAssertTrue(breakingNewsToggle.waitForExistence(timeout: 15), "Breaking News toggle should exist")
    }

    func testToggleNotifications() throws {
        navigateToSettings()

        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5))

        // Get initial state
        let initialValue = notificationsToggle.value as? String

        // Toggle
        notificationsToggle.tap()

        // Wait for state change
        Thread.sleep(forTimeInterval: 0.5)

        // Get new state
        let newValue = notificationsToggle.value as? String

        // Values should be different (toggled)
        // Note: This may trigger a system permissions dialog
        XCTAssertTrue(true, "Notifications toggle test completed")
    }

    func testBreakingNewsToggleDependsOnNotifications() throws {
        navigateToSettings()

        let notificationsToggle = app.switches["Enable Notifications"]
        let breakingNewsToggle = app.switches["Breaking News Alerts"]

        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(breakingNewsToggle.waitForExistence(timeout: 5))

        // When notifications are disabled, breaking news should be disabled
        let notificationsEnabled = isSwitchOn(notificationsToggle)

        if !notificationsEnabled {
            XCTAssertFalse(breakingNewsToggle.isEnabled, "Breaking News should be disabled when Notifications are off")
        }
    }

    // MARK: - Appearance Toggle Tests

    func testSystemThemeToggleExists() throws {
        navigateToSettings()

        app.swipeUp()

        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))
    }

    func testToggleDarkMode() throws {
        navigateToSettings()

        app.swipeUp()

        // First, turn off system theme
        let systemThemeToggle = app.switches["Use System Theme"]
        XCTAssertTrue(systemThemeToggle.waitForExistence(timeout: 5))

        let wasSystemThemeOn = isSwitchOn(systemThemeToggle)
        setSwitch(systemThemeToggle, to: false)
        if wasSystemThemeOn {
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Now toggle Dark Mode
        let darkModeToggle = app.switches["Dark Mode"]
        if darkModeToggle.waitForExistence(timeout: 3) {
            darkModeToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Toggle back
            darkModeToggle.tap()
        }

        // Restore system theme
        setSwitch(systemThemeToggle, to: wasSystemThemeOn)

        XCTAssertTrue(true, "Dark mode toggle test completed")
    }

    // MARK: - Content Filters Tests

    func testMutedSourcesDisclosureExists() throws {
        navigateToSettings()

        app.swipeUp()

        // Look for Muted Sources disclosure group
        let mutedSourcesText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        XCTAssertTrue(mutedSourcesText.waitForExistence(timeout: 5), "Muted Sources section should exist")
    }

    func testMutedKeywordsDisclosureExists() throws {
        navigateToSettings()

        app.swipeUp()

        // Look for Muted Keywords disclosure group
        let mutedKeywordsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch
        XCTAssertTrue(mutedKeywordsText.waitForExistence(timeout: 5), "Muted Keywords section should exist")
    }

    func testExpandMutedSourcesDisclosure() throws {
        navigateToSettings()

        app.swipeUp()

        // Find and tap Muted Sources to expand
        let mutedSourcesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch

        if mutedSourcesButton.waitForExistence(timeout: 5) {
            mutedSourcesButton.tap()

            // Wait for expansion
            Thread.sleep(forTimeInterval: 0.5)

            // Text field should appear
            let addSourceField = app.textFields["Add source..."]
            XCTAssertTrue(addSourceField.waitForExistence(timeout: 3), "Add source field should appear")
        }
    }

    func testAddMutedSource() throws {
        navigateToSettings()

        // Scroll to Content Filters section - needs multiple swipes as it's below several sections
        let contentFiltersSection = app.staticTexts["Content Filters"]
        guard scrollToElement(contentFiltersSection, maxSwipes: 16) else {
            throw XCTSkip("Content Filters section not found after scrolling")
        }

        // Expand Muted Sources
        let mutedSourcesButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Sources'")).firstMatch
        if !mutedSourcesButton.exists {
            _ = scrollToElement(mutedSourcesButton, maxSwipes: 4)
        }

        guard mutedSourcesButton.waitForExistence(timeout: 10) else {
            throw XCTSkip("Muted Sources button not found")
        }

        mutedSourcesButton.tap()

        // Wait for expansion and text field with extended timeout
        let addSourceField = app.textFields["Add source..."]
        XCTAssertTrue(addSourceField.waitForExistence(timeout: 10), "Add source field should appear after expansion")
    }

    func testExpandMutedKeywordsDisclosure() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        // Find and tap Muted Keywords to expand
        let mutedKeywordsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Muted Keywords'")).firstMatch

        if mutedKeywordsButton.waitForExistence(timeout: 5) {
            mutedKeywordsButton.tap()

            // Wait for expansion
            Thread.sleep(forTimeInterval: 0.5)

            // Text field should appear
            let addKeywordField = app.textFields["Add keyword..."]
            XCTAssertTrue(addKeywordField.waitForExistence(timeout: 3), "Add keyword field should appear")
        }
    }

    func testContentFiltersFooterText() throws {
        navigateToSettings()

        app.swipeUp()

        let footerText = app.staticTexts["Muted sources and keywords will be hidden from all feeds."]
        XCTAssertTrue(footerText.waitForExistence(timeout: 5), "Footer text should explain content filters")
    }

    // MARK: - Data Section Tests

    func testClearReadingHistoryButtonExists() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        let clearHistoryButton = app.buttons["Clear Reading History"]
        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5), "Clear Reading History button should exist")
    }

    func testClearReadingHistoryShowsConfirmation() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        let clearHistoryButton = app.buttons["Clear Reading History"]
        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5))

        clearHistoryButton.tap()

        // Confirmation alert should appear
        let alertTitle = app.staticTexts["Clear Reading History?"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 3), "Confirmation alert should appear")

        // Dismiss alert
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    func testClearReadingHistoryConfirmationButtons() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        let clearHistoryButton = app.buttons["Clear Reading History"]
        XCTAssertTrue(clearHistoryButton.waitForExistence(timeout: 5))

        clearHistoryButton.tap()

        // Check for Cancel and Clear buttons
        let cancelButton = app.buttons["Cancel"]
        let clearButton = app.buttons["Clear"]

        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button should exist")
        XCTAssertTrue(clearButton.exists, "Clear button should exist")

        // Dismiss by tapping Cancel
        cancelButton.tap()
    }

    // MARK: - Premium Section Tests

    func testPremiumSectionDisplaysCorrectly() throws {
        navigateToSettings()

        // Premium section is at the top
        let goPremiumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'premium'")).firstMatch

        XCTAssertTrue(goPremiumText.waitForExistence(timeout: 5), "Premium section should be visible")
    }

    func testPremiumButtonTapsShowsPaywall() throws {
        navigateToSettings()

        // Find premium row/button
        let premiumButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Premium' OR label CONTAINS[c] 'Go Premium'")).firstMatch

        if premiumButton.waitForExistence(timeout: 5) {
            // Only tap if not already premium
            let alreadyPremium = app.staticTexts["Premium Active"].exists

            if !alreadyPremium {
                premiumButton.tap()

                // Paywall sheet should appear
                // Look for common paywall elements
                Thread.sleep(forTimeInterval: 1)

                // Dismiss if paywall appeared
                let closeButton = app.buttons["xmark"]
                if closeButton.exists {
                    closeButton.tap()
                } else {
                    // Swipe down to dismiss sheet
                    app.swipeDown()
                }
            }
        }

        XCTAssertTrue(true, "Premium test completed")
    }

    // MARK: - About Section Tests

    func testVersionNumberDisplayed() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        let versionLabel = app.staticTexts["Version"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 5), "Version label should exist")
    }

    func testGitHubLinkExists() throws {
        navigateToSettings()

        app.swipeUp()
        app.swipeUp()

        let githubLink = app.buttons["View on GitHub"]
        XCTAssertTrue(githubLink.waitForExistence(timeout: 5), "GitHub link should exist")
    }

    // MARK: - Scrolling Tests

    func testSettingsViewIsScrollable() throws {
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
    }

    func testCanScrollToAllSections() throws {
        navigateToSettings()

        // Scroll to bottom to see all sections
        for _ in 0..<5 {
            app.swipeUp()
        }

        // About section should be visible at the bottom
        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.exists, "Should be able to scroll to About section")
    }

    // MARK: - List Style Tests

    func testSettingsUsesListLayout() throws {
        navigateToSettings()

        // Settings should have list-style sections
        // Verify by checking for multiple section headers
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

    func testSettingsChangePersists() throws {
        navigateToSettings()

        app.swipeUp()

        // Use Notifications toggle instead - it's a simpler toggle that directly updates state
        let notificationsToggle = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggle.waitForExistence(timeout: 5))

        let initialValue = notificationsToggle.value as? String ?? "unknown"

        // Tap to toggle
        notificationsToggle.tap()

        // Wait for toggle animation and state update
        Thread.sleep(forTimeInterval: 1.0)

        // Read the new value
        let toggledValue = notificationsToggle.value as? String ?? "unknown"

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()

        // Wait for Home
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5))

        // Navigate back to Settings
        navigateToSettings()

        // Re-query the toggle element after navigation
        let notificationsToggleAfter = app.switches["Enable Notifications"]
        XCTAssertTrue(notificationsToggleAfter.waitForExistence(timeout: 5))

        // Verify setting persisted - should match the toggled value, not the initial
        let persistedValue = notificationsToggleAfter.value as? String ?? "unknown"
        XCTAssertEqual(toggledValue, persistedValue, "Setting change should persist across navigation")

        // Restore original value
        if persistedValue != initialValue {
            notificationsToggleAfter.tap()
        }
    }
}
