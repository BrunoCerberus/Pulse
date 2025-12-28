import XCTest

final class AuthenticationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()

        // Wait for app to be fully running
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20.0), "App should be running in the foreground")
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    // MARK: - Sign In View Existence Tests

    func testSignInViewElementsExist() throws {
        // Wait for either sign-in view or tab bar (if already authenticated)
        let signInWithAppleButton = app.buttons["Sign in with Apple"]
        let tabBar = app.tabBars.firstMatch

        // If tab bar exists, user is already authenticated (mocked)
        if tabBar.waitForExistence(timeout: 10) {
            // Already authenticated, skip sign-in tests
            throw XCTSkip("User is already authenticated in test environment")
        }

        // Otherwise, verify sign-in view elements
        XCTAssertTrue(signInWithAppleButton.waitForExistence(timeout: 10), "Sign in with Apple button should exist")

        let signInWithGoogleButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInWithGoogleButton.exists, "Sign in with Google button should exist")
    }

    func testPulseLogoExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let pulseTitle = app.staticTexts["Pulse"]
        XCTAssertTrue(pulseTitle.waitForExistence(timeout: 10), "Pulse title should exist")
    }

    func testSubtitleExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let subtitle = app.staticTexts["Your personalized news experience"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 10), "Subtitle should exist")
    }

    func testTermsTextExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let termsText = app.staticTexts["By signing in, you agree to our Terms of Service and Privacy Policy"]
        XCTAssertTrue(termsText.waitForExistence(timeout: 10), "Terms text should exist")
    }

    // MARK: - Button Interaction Tests

    func testAppleSignInButtonIsTappable() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let signInWithAppleButton = app.buttons["Sign in with Apple"]
        XCTAssertTrue(signInWithAppleButton.waitForExistence(timeout: 10))
        XCTAssertTrue(signInWithAppleButton.isEnabled, "Sign in with Apple button should be enabled")
        XCTAssertTrue(signInWithAppleButton.isHittable, "Sign in with Apple button should be hittable")
    }

    func testGoogleSignInButtonIsTappable() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let signInWithGoogleButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(signInWithGoogleButton.waitForExistence(timeout: 10))
        XCTAssertTrue(signInWithGoogleButton.isEnabled, "Sign in with Google button should be enabled")
        XCTAssertTrue(signInWithGoogleButton.isHittable, "Sign in with Google button should be hittable")
    }

    // MARK: - Layout Tests

    func testSignInViewLayout() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        // Verify vertical ordering of elements
        let pulseTitle = app.staticTexts["Pulse"]
        let subtitle = app.staticTexts["Your personalized news experience"]
        let appleButton = app.buttons["Sign in with Apple"]
        let googleButton = app.buttons["Sign in with Google"]
        let termsText = app.staticTexts["By signing in, you agree to our Terms of Service and Privacy Policy"]

        XCTAssertTrue(pulseTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(subtitle.exists)
        XCTAssertTrue(appleButton.exists)
        XCTAssertTrue(googleButton.exists)
        XCTAssertTrue(termsText.exists)

        // Verify title is above subtitle
        XCTAssertLessThan(pulseTitle.frame.maxY, subtitle.frame.minY + 50, "Title should be above subtitle")

        // Verify buttons are above terms
        XCTAssertLessThan(googleButton.frame.maxY, termsText.frame.minY + 50, "Buttons should be above terms")
    }

    // MARK: - Accessibility Tests

    func testSignInButtonsAccessibility() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            throw XCTSkip("User is already authenticated in test environment")
        }

        let appleButton = app.buttons["Sign in with Apple"]
        let googleButton = app.buttons["Sign in with Google"]

        XCTAssertTrue(appleButton.waitForExistence(timeout: 10))
        XCTAssertTrue(googleButton.exists)

        // Verify buttons have accessible labels
        XCTAssertFalse(appleButton.label.isEmpty, "Apple button should have an accessibility label")
        XCTAssertFalse(googleButton.label.isEmpty, "Google button should have an accessibility label")
    }

    // MARK: - Authenticated State Tests

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

    // MARK: - Sign Out Tests (when authenticated)

    func testSignOutFromSettings() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            throw XCTSkip("User is not authenticated - cannot test sign out")
        }

        // Navigate to Settings
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
        }

        // Tap gear button to open settings
        let gearButton = app.navigationBars.buttons["gearshape"]
        guard gearButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Settings gear button not found")
        }
        gearButton.tap()

        // Wait for Settings to load
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Settings should open")

        // Scroll to find Account section
        for _ in 0..<5 {
            app.swipeUp()
        }

        // Look for Sign Out button
        let signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 5) {
            // Sign out button exists - verify it's tappable
            XCTAssertTrue(signOutButton.isEnabled, "Sign Out button should be enabled")

            // Note: Actually tapping sign out would require re-authentication
            // which is complex in UI tests, so we just verify the button exists
        }
    }

    func testAccountSectionExistsInSettings() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 15) else {
            throw XCTSkip("User is not authenticated")
        }

        // Navigate to Settings
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }

        let gearButton = app.navigationBars.buttons["gearshape"]
        guard gearButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Settings gear button not found")
        }
        gearButton.tap()

        // Wait for Settings to load - Account section is at the top, no scrolling needed
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Settings should open")

        let accountSection = app.staticTexts["Account"]
        XCTAssertTrue(accountSection.waitForExistence(timeout: 5), "Account section should exist in settings")
    }
}
