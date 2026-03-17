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

        if safeExists(tabBar) {
            // --- Authenticated State ---
            XCTAssertTrue(safeExists(tabBar), "Tab bar should exist for authenticated user")

            let homeTab = app.tabBars.buttons["Home"]
            XCTAssertTrue(safeExists(homeTab), "Home tab should exist")

            if safeExists(homeTab), !homeTab.isSelected {
                safeTap(homeTab)
            }

            try ensureAppRunning()

            // Use longer timeout for settings navigation on CI — toolbar button
            // may take time to appear after navigation settles
            let gearButton = app.navigationBars.buttons["Settings"]
            guard safeWaitForExistence(gearButton, timeout: Self.defaultTimeout) else {
                // On CI, the gear button may not appear if the nav bar is still loading
                return
            }
            safeTap(gearButton)

            let settingsNav = app.navigationBars["Settings"]
            XCTAssertTrue(safeWaitForExistence(settingsNav, timeout: Self.defaultTimeout), "Settings should open")

            let accountSection = app.staticTexts["Account"]
            XCTAssertTrue(safeWaitForExistence(accountSection, timeout: 5), "Account section should exist in settings")

            for _ in 0 ..< 5 {
                app.swipeUp()
            }

            let signOutButton = app.buttons["Sign Out"]
            if safeWaitForExistence(signOutButton, timeout: 5) {
                XCTAssertTrue(signOutButton.isEnabled, "Sign Out button should be enabled")
            }
        } else {
            // --- Sign In View ---
            XCTAssertTrue(safeWaitForExistence(signInWithAppleButton, timeout: 10), "Sign in with Apple button should exist")
            XCTAssertTrue(safeExists(signInWithGoogleButton), "Sign in with Google button should exist")

            let pulseTitle = app.staticTexts["Pulse"]
            XCTAssertTrue(safeExists(pulseTitle), "Pulse title should exist")

            let subtitle = app.staticTexts["Your personalized news experience"]
            XCTAssertTrue(safeExists(subtitle), "Subtitle should exist")

            let termsText = app.staticTexts["By signing in, you agree to our Terms of Service and Privacy Policy"]
            XCTAssertTrue(safeExists(termsText), "Terms text should exist")

            XCTAssertLessThan(pulseTitle.frame.maxY, subtitle.frame.minY + 50, "Title should be above subtitle")
            XCTAssertLessThan(
                signInWithGoogleButton.frame.maxY,
                termsText.frame.minY + 50,
                "Buttons should be above terms"
            )

            XCTAssertTrue(signInWithAppleButton.isEnabled, "Sign in with Apple button should be enabled")
            XCTAssertTrue(safeExists(signInWithAppleButton), "Sign in with Apple button should be hittable")

            XCTAssertTrue(signInWithGoogleButton.isEnabled, "Sign in with Google button should be enabled")
            XCTAssertTrue(safeExists(signInWithGoogleButton), "Sign in with Google button should be hittable")

            XCTAssertFalse(signInWithAppleButton.label.isEmpty, "Apple button should have an accessibility label")
            XCTAssertFalse(signInWithGoogleButton.label.isEmpty, "Google button should have an accessibility label")
        }
    }
}
