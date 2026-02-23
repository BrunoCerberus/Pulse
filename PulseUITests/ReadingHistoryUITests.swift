import XCTest

final class ReadingHistoryUITests: BaseUITestCase {
    // MARK: - Combined Flow Test

    /// Tests reading history navigation via Settings, content states, and navigation
    func testReadingHistoryFlow() {
        // --- Navigate to Settings ---
        navigateToSettings()

        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: Self.defaultTimeout), "Should be on Settings")

        // --- Find and tap Reading History row ---
        let readingHistoryRow = app.staticTexts["Reading History"]

        if !readingHistoryRow.exists {
            let settingsScroll = app.scrollViews.firstMatch
            if settingsScroll.exists {
                scrollToElement(readingHistoryRow, in: settingsScroll)
            }
        }

        XCTAssertTrue(readingHistoryRow.waitForExistence(timeout: Self.defaultTimeout), "Reading History row should exist in Settings")
        readingHistoryRow.tap()

        // --- Verify Reading History screen ---
        let readingHistoryNav = app.navigationBars["Reading History"]
        XCTAssertTrue(readingHistoryNav.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Reading History' should exist")

        // --- Wait for content ---
        let noHistoryText = app.staticTexts["No Reading History"]
        let emptyMessage = app.staticTexts["Articles you read will appear here."]
        let loadingIndicator = app.activityIndicators.firstMatch
        let scrollView = app.scrollViews.firstMatch

        let contentLoaded = waitForAny([noHistoryText, scrollView, loadingIndicator], timeout: Self.defaultTimeout)
        XCTAssertTrue(contentLoaded, "Reading History should show empty state, content, or loading")

        // --- Empty state verification ---
        if noHistoryText.exists {
            XCTAssertTrue(emptyMessage.exists, "Empty state should show helpful message")
        }

        // --- Populated state: scroll and article navigation ---
        if scrollView.exists, !noHistoryText.exists {
            let cards = articleCards()

            if cards.count > 0 {
                cards.firstMatch.tap()

                let backButton = app.buttons["backButton"]
                XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Should navigate to article detail")

                backButton.tap()

                let readingHistoryNavAfter = app.navigationBars["Reading History"]
                XCTAssertTrue(readingHistoryNavAfter.waitForExistence(timeout: 5), "Should return to Reading History")
            }
        }

        // --- Clear button interaction ---
        let trashButton = readingHistoryNav.buttons["trash"]

        if trashButton.exists {
            trashButton.tap()

            // Verify confirmation alert appears
            let clearHistoryAlert = app.alerts.firstMatch
            if clearHistoryAlert.waitForExistence(timeout: 3) {
                // Cancel to preserve state
                let cancelButton = clearHistoryAlert.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    // Dismiss alert
                    app.tap()
                }
            }
        }

        // --- Navigate back to Settings ---
        let backButton = app.buttons["backButton"]
        if backButton.exists {
            backButton.tap()
        } else {
            navigateBack()
        }

        let settingsNavAfter = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavAfter.waitForExistence(timeout: Self.defaultTimeout), "Should return to Settings")
    }
}
