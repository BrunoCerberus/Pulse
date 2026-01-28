import XCTest

final class AuthenticationUITests: BaseUITestCase {
    // MARK: - Combined Flow Test

    /// Tests authentication UI states and settings account section when authenticated
    func testAuthenticationFlow() throws {
        let tabBar = app.tabBars.firstMatch
        let signInWithAppleButton = app.buttons["Sign in with Apple"]
        let signInWithGoogleButton = app.buttons["Sign in with Google"]

        // Use waitForAny to check both elements concurrently, avoiding sequential timeout issues
        let stateResolved = waitForAny([tabBar, signInWithAppleButton], timeout: Self.launchTimeout)
        XCTAssertTrue(stateResolved, "Either tab bar or sign in button should appear")

        if tabBar.exists {
            // --- Authenticated State ---
            XCTAssertTrue(tabBar.exists, "Tab bar should exist for authenticated user")

            let homeTab = app.tabBars.buttons["Home"]
            XCTAssertTrue(homeTab.exists, "Home tab should exist")

            if homeTab.exists, !homeTab.isSelected {
                homeTab.tap()
            }

            let gearButton = app.navigationBars.buttons["gearshape"]
            XCTAssertTrue(gearButton.waitForExistence(timeout: 5), "Settings gear button should exist")
            gearButton.tap()

            let settingsNav = app.navigationBars["Settings"]
            XCTAssertTrue(settingsNav.waitForExistence(timeout: 5), "Settings should open")

            let accountSection = app.staticTexts["Account"]
            XCTAssertTrue(accountSection.waitForExistence(timeout: 5), "Account section should exist in settings")

            for _ in 0 ..< 5 {
                app.swipeUp()
            }

            let signOutButton = app.buttons["Sign Out"]
            if signOutButton.waitForExistence(timeout: 5) {
                XCTAssertTrue(signOutButton.isEnabled, "Sign Out button should be enabled")
            }
        } else {
            // --- Sign In View ---
            XCTAssertTrue(signInWithAppleButton.waitForExistence(timeout: 10), "Sign in with Apple button should exist")
            XCTAssertTrue(signInWithGoogleButton.exists, "Sign in with Google button should exist")

            let pulseTitle = app.staticTexts["Pulse"]
            XCTAssertTrue(pulseTitle.exists, "Pulse title should exist")

            let subtitle = app.staticTexts["Your personalized news experience"]
            XCTAssertTrue(subtitle.exists, "Subtitle should exist")

            let termsText = app.staticTexts["By signing in, you agree to our Terms of Service and Privacy Policy"]
            XCTAssertTrue(termsText.exists, "Terms text should exist")

            XCTAssertLessThan(pulseTitle.frame.maxY, subtitle.frame.minY + 50, "Title should be above subtitle")
            XCTAssertLessThan(signInWithGoogleButton.frame.maxY, termsText.frame.minY + 50, "Buttons should be above terms")

            XCTAssertTrue(signInWithAppleButton.isEnabled, "Sign in with Apple button should be enabled")
            XCTAssertTrue(signInWithAppleButton.isHittable, "Sign in with Apple button should be hittable")

            XCTAssertTrue(signInWithGoogleButton.isEnabled, "Sign in with Google button should be enabled")
            XCTAssertTrue(signInWithGoogleButton.isHittable, "Sign in with Google button should be hittable")

            XCTAssertFalse(signInWithAppleButton.label.isEmpty, "Apple button should have an accessibility label")
            XCTAssertFalse(signInWithGoogleButton.label.isEmpty, "Google button should have an accessibility label")
        }
    }
}
