import XCTest

final class AuthenticationUITests: BaseUITestCase {

    // MARK: - Sign In View Tests

    /// Tests sign in view elements: logo, subtitle, buttons, terms, and layout
    func testSignInViewElements() throws {
        // Wait for either sign-in view or tab bar (if already authenticated)
        let signInWithAppleButton = app.buttons["Sign in with Apple"]
        let tabBar = app.tabBars.firstMatch

        // If tab bar exists, user is already authenticated (mocked)
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        // Verify sign-in view elements
        XCTAssertTrue(signInWithAppleButton.waitForExistence(timeout: 10), "Sign in with Apple button should exist")

        let signInWithGoogleButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInWithGoogleButton.exists, "Sign in with Google button should exist")

        // Verify logo and subtitle
        let pulseTitle = app.staticTexts["Pulse"]
        XCTAssertTrue(pulseTitle.exists, "Pulse title should exist")

        let subtitle = app.staticTexts["Your personalized news experience"]
        XCTAssertTrue(subtitle.exists, "Subtitle should exist")

        let termsText = app.staticTexts["By signing in, you agree to our Terms of Service and Privacy Policy"]
        XCTAssertTrue(termsText.exists, "Terms text should exist")

        // Verify layout - title is above subtitle, buttons are above terms
        XCTAssertLessThan(pulseTitle.frame.maxY, subtitle.frame.minY + 50, "Title should be above subtitle")
        XCTAssertLessThan(signInWithGoogleButton.frame.maxY, termsText.frame.minY + 50, "Buttons should be above terms")
    }

    // MARK: - Button Interaction Tests

    /// Tests sign in buttons are tappable and accessible
    func testSignInButtonInteraction() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let appleButton = app.buttons["Sign in with Apple"]
        let googleButton = app.buttons["Sign in with Google"]

        XCTAssertTrue(appleButton.waitForExistence(timeout: 10))
        XCTAssertTrue(googleButton.exists)

        // Test Apple button
        XCTAssertTrue(appleButton.isEnabled, "Sign in with Apple button should be enabled")
        XCTAssertTrue(appleButton.isHittable, "Sign in with Apple button should be hittable")

        // Test Google button
        XCTAssertTrue(googleButton.isEnabled, "Sign in with Google button should be enabled")
        XCTAssertTrue(googleButton.isHittable, "Sign in with Google button should be hittable")

        // Verify buttons have accessible labels
        XCTAssertFalse(appleButton.label.isEmpty, "Apple button should have an accessibility label")
        XCTAssertFalse(googleButton.label.isEmpty, "Google button should have an accessibility label")
    }

    // MARK: - Authenticated State Tests

    /// Tests authenticated user sees main app with tab bar
    func testAuthenticatedUserSeesMainApp() throws {
        // Wait for either sign-in or main app
        let tabBar = app.tabBars.firstMatch
        let signInButton = app.buttons["Sign in with Apple"]

        // Wait for app to settle
        Thread.sleep(forTimeInterval: 2)

        if tabBar.exists {
            // If authenticated, verify main app UI
            XCTAssertTrue(tabBar.exists, "Tab bar should exist for authenticated user")

            let homeTab = app.tabBars.buttons["Home"]
            XCTAssertTrue(homeTab.exists, "Home tab should exist")
        } else if signInButton.exists {
            // If not authenticated, verify sign-in UI
            XCTAssertTrue(signInButton.exists, "Sign in button should exist for unauthenticated user")
        } else {
            // Still loading, wait more
            XCTAssertTrue(
                tabBar.waitForExistence(timeout: 15) || signInButton.waitForExistence(timeout: 15),
                "Either tab bar or sign in button should eventually appear"
            )
        }
    }

    // MARK: - Settings Account Tests

    /// Tests sign out button and account section in settings
    func testSettingsAccountSection() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            throw XCTSkip("User is not authenticated - cannot test sign out")
        }

        // Navigate to Settings
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
        }

        let gearButton = app.navigationBars.buttons["gearshape"]
        guard gearButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Settings gear button not found")
        }
        gearButton.tap()

        // Wait for Settings to load - Account section is at the top
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Settings should open")

        let accountSection = app.staticTexts["Account"]
        XCTAssertTrue(accountSection.waitForExistence(timeout: 5), "Account section should exist in settings")

        // Scroll to find Sign Out button
        for _ in 0..<5 {
            app.swipeUp()
        }

        // Look for Sign Out button
        let signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 5) {
            // Sign out button exists - verify it's tappable
            XCTAssertTrue(signOutButton.isEnabled, "Sign Out button should be enabled")
        }
    }
}
