import XCTest

final class ReadingHistoryUITests: BaseUITestCase {
    // MARK: - Helpers

    /// Settings scroll container - prefers table (List renders as UITableView)
    private func settingsScrollContainer() -> XCUIElement {
        let table = app.tables.firstMatch
        if table.exists { return table }
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists { return scrollView }
        return app
    }

    /// Find the Reading History row using multiple accessibility strategies
    private func findReadingHistoryRow() -> XCUIElement? {
        // Strategy 1: Button with label (NavigationLink renders as button)
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Reading History'")).firstMatch
        if button.waitForExistence(timeout: 3) { return button }

        // Strategy 2: Static text (some iOS versions expose Label text directly)
        let text = app.staticTexts["Reading History"]
        if text.waitForExistence(timeout: 2) { return text }

        return nil
    }

    // MARK: - Combined Flow Test

    /// Tests reading history navigation via Settings, content states, and navigation
    func testReadingHistoryFlow() {
        // --- Navigate to Settings ---
        navigateToSettings()

        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: Self.defaultTimeout), "Should be on Settings")

        // Wait for Settings list to stabilize on CI
        wait(for: 1.0)

        // --- Find Reading History row (Data section is far down, needs scrolling) ---
        let container = settingsScrollContainer()
        var readingHistoryRow = findReadingHistoryRow()

        if readingHistoryRow == nil {
            // Scroll down to find it — Data section is after 6 other sections
            for _ in 0 ..< 8 {
                container.swipeUp()
                wait(for: 0.3)
                readingHistoryRow = findReadingHistoryRow()
                if readingHistoryRow != nil { break }
            }
        }

        guard let row = readingHistoryRow else {
            XCTFail("Reading History row should exist in Settings")
            return
        }

        // Ensure element is hittable before tapping
        if !row.isHittable {
            container.swipeUp()
            wait(for: 0.3)
        }

        row.tap()

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

            if cards.firstMatch.waitForExistence(timeout: Self.defaultTimeout), cards.count > 0 {
                let firstCard = cards.firstMatch

                if firstCard.isHittable {
                    firstCard.tap()

                    let detailBack = app.buttons["backButton"]
                    if detailBack.waitForExistence(timeout: Self.defaultTimeout) {
                        detailBack.tap()
                        XCTAssertTrue(readingHistoryNav.waitForExistence(timeout: Self.defaultTimeout), "Should return to Reading History")
                    }
                }
            }
        }

        // --- Clear button interaction ---
        let trashButton = readingHistoryNav.buttons["trash"]

        if trashButton.waitForExistence(timeout: 3) {
            trashButton.tap()

            let clearHistoryAlert = app.alerts.firstMatch
            if clearHistoryAlert.waitForExistence(timeout: 3) {
                let cancelButton = clearHistoryAlert.buttons["Cancel"]
                if cancelButton.waitForExistence(timeout: 2) {
                    cancelButton.tap()
                }
            }
        }

        // --- Navigate back to Settings ---
        navigateBack()

        let settingsNavAfter = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavAfter.waitForExistence(timeout: Self.defaultTimeout), "Should return to Settings")
    }
}
