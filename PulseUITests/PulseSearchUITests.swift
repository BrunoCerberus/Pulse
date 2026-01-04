import XCTest

final class PulseSearchUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Dismiss keyboard if visible
    private func dismissKeyboard() {
        if app.keyboards.element.exists {
            app.keyboards.buttons["return"].tap()
        }
    }

    /// Submit search via keyboard
    private func submitSearch() {
        guard app.keyboards.element.exists else { return }

        // Try different button identifiers for the search key
        let searchButton = app.keyboards.buttons["search"]
        if searchButton.exists {
            searchButton.tap()
            return
        }

        let searchButtonCap = app.keyboards.buttons["Search"]
        if searchButtonCap.exists {
            searchButtonCap.tap()
            return
        }

        // Fallback: tap return/go key
        let returnButton = app.keyboards.buttons["return"]
        if returnButton.exists {
            returnButton.tap()
            return
        }

        let goButton = app.keyboards.buttons["Go"]
        if goButton.exists {
            goButton.tap()
        }
    }

    private func clearSearchFieldIfNeeded(_ searchField: XCUIElement) {
        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
            return
        }

        let currentValue = searchField.value as? String ?? ""
        let placeholderValue = searchField.placeholderValue ?? ""
        if currentValue.isEmpty || currentValue == placeholderValue {
            return
        }

        searchField.tap()
        let deleteString = String(repeating: "\u{8}", count: currentValue.count)
        searchField.typeText(deleteString)
    }

    // MARK: - Combined Flow Test

    /// Tests search UI, input, sorting, keyboard behavior, and tab switching
    func testSearchFlow() throws {
        // --- Search UI, Initial State, and Suggestions ---
        navigateToSearchTab()

        let searchNav = app.navigationBars["Search"]
        XCTAssertTrue(searchNav.waitForExistence(timeout: Self.defaultTimeout), "Search navigation should load")

        let searchField = app.searchFields.firstMatch
        let searchForNews = app.staticTexts["Search for News"]
        let searchSubtitle = app.staticTexts["Find articles from thousands of sources worldwide"]

        let searchUILoaded = waitForAny([searchField, searchForNews, searchSubtitle], timeout: 20)

        XCTAssertTrue(searchUILoaded, "Search UI should load (search field or empty state)")
        XCTAssertTrue(searchForNews.exists || searchSubtitle.exists || searchField.exists, "Initial empty state should show search prompt")

        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be interactable")
            searchField.tap()

            let keyboard = app.keyboards.element
            XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear for text input")

            let trendingHeader = app.staticTexts["Trending Topics"]
            let recentHeader = app.staticTexts["Recent Searches"]

            let hasSuggestions = trendingHeader.exists || recentHeader.exists || searchForNews.exists
            XCTAssertTrue(hasSuggestions, "Should show suggestions or empty state")

            let categoryNames = ["Technology", "Business", "World", "Science"]
            var didTapCategory = false
            for category in categoryNames {
                let categoryButton = app.buttons[category]
                if categoryButton.exists {
                    categoryButton.tap()

                    // Wait for search to start - empty state should disappear or results appear
                    _ = waitForAnyMatch(articleCards(), timeout: 5)
                    let emptyStateGone = !app.staticTexts["Search for News"].exists
                    XCTAssertTrue(emptyStateGone, "Tapping category should start search")
                    didTapCategory = true
                    break
                }
            }

            if didTapCategory {
                clearSearchFieldIfNeeded(searchField)
            }
        }

        // --- Search Input, Results, and Clear/Cancel ---
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        clearSearchFieldIfNeeded(searchField)
        searchField.tap()
        searchField.typeText("Apple")
        submitSearch()

        let noResultsText = app.staticTexts["No Results Found"]
        let searchingText = app.staticTexts["Searching..."]
        let errorText = app.staticTexts["Search Failed"]

        let hasContent = waitForAny([noResultsText, searchingText, errorText], timeout: 15) ||
            waitForAnyMatch(articleCards(), timeout: 1) ||
            !app.staticTexts["Search for News"].exists

        XCTAssertTrue(hasContent, "Search should show results, loading, or status message")

        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 3) {
            clearButton.tap()

            // Wait for empty state to return or field to clear
            let emptyStateReturned = waitForAny([searchForNews, searchSubtitle], timeout: 3)
            var fieldValue = app.searchFields.firstMatch.value as? String ?? ""
            var isCleared = emptyStateReturned || !fieldValue.lowercased().contains("apple")

            if !isCleared {
                clearSearchFieldIfNeeded(searchField)
                fieldValue = app.searchFields.firstMatch.value as? String ?? ""
                isCleared = !fieldValue.lowercased().contains("apple") || fieldValue.isEmpty
            }

            XCTAssertTrue(isCleared, "Search field should be cleared")
        }

        searchField.tap()
        searchField.typeText("test query")
        let cancelButton = app.buttons["Cancel"]

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
            XCTAssertTrue(!app.keyboards.element.waitForExistence(timeout: 1), "Keyboard should dismiss after cancel")
        }

        // --- Sort, Navigation, and Content States ---
        clearSearchFieldIfNeeded(searchField)
        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        // Wait for results to load
        _ = waitForAnyMatch(articleCards(), timeout: 5)

        let segmentedControl = app.segmentedControls.firstMatch

        if segmentedControl.exists {
            let segments = segmentedControl.buttons
            if segments.count > 1 {
                segments.element(boundBy: 1).tap()
            }
        }

        XCTAssertTrue(searchField.exists, "Search view should remain functional")

        let articleCardsForNavigation = articleCards()

        if articleCardsForNavigation.count > 0 {
            articleCardsForNavigation.firstMatch.tap()

            let backButton = app.navigationBars.buttons.firstMatch
            let didNavigate = backButton.waitForExistence(timeout: 5) && !searchField.isHittable

            if didNavigate {
                backButton.tap()
                XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search")
            }
        }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
            scrollView.swipeUp()
        }

        XCTAssertTrue(searchField.exists, "Search should remain functional after scrolling")

        let clearButtonForNoResults = app.searchFields.buttons["Clear text"]
        if clearButtonForNoResults.exists {
            clearButtonForNoResults.tap()
        }

        searchField.tap()
        searchField.typeText("xyzqwerty123456789unlikely")
        submitSearch()

        let noResultsTextAfter = app.staticTexts["No Results Found"]
        let errorTextAfter = app.staticTexts["Search Failed"]

        // Wait for any response
        let hasResponse = waitForAny([noResultsTextAfter, errorTextAfter], timeout: 5) ||
            articleCards().count > 0

        XCTAssertTrue(hasResponse, "Search should show a response")

        if errorTextAfter.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }

        // --- Keyboard Behavior ---
        clearSearchFieldIfNeeded(searchField)
        searchField.tap()
        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear")

        searchField.typeText("test")
        XCTAssertTrue(app.keyboards.element.exists, "Keyboard should be shown")
        submitSearch()
        dismissKeyboard()

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()

        navigateToSearchTab()

        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search view")
    }
}
