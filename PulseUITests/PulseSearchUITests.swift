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

        let timeout: TimeInterval = 20
        let startTime = Date()
        var searchUILoaded = false

        while Date().timeIntervalSince(startTime) < timeout {
            if searchField.exists || searchForNews.exists || searchSubtitle.exists {
                searchUILoaded = true
                break
            }
            wait(for: 0.5)
        }

        XCTAssertTrue(searchUILoaded, "Search UI should load (search field or empty state)")
        XCTAssertTrue(searchForNews.exists || searchSubtitle.exists || searchField.exists, "Initial empty state should show search prompt")

        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be interactable")
            searchField.tap()

            let keyboard = app.keyboards.element
            XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear for text input")

            wait(for: 1)

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
                    wait(for: 2)

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

        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        let noResultsText = app.staticTexts["No Results Found"]
        let searchingText = app.staticTexts["Searching..."]
        let errorText = app.staticTexts["Search Failed"]

        let resultsTimeout: TimeInterval = 15
        let resultsStartTime = Date()
        var hasContent = false

        while Date().timeIntervalSince(resultsStartTime) < resultsTimeout {
            if articleCards.count > 0 || noResultsText.exists || searchingText.exists || errorText.exists {
                hasContent = true
                break
            }
            wait(for: 0.5)
        }

        if !hasContent {
            hasContent = !app.staticTexts["Search for News"].exists
        }

        XCTAssertTrue(hasContent, "Search should show results, loading, or status message")

        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 3) {
            clearButton.tap()

            let clearTimeout: TimeInterval = 5
            let clearStartTime = Date()
            var isCleared = false

            while Date().timeIntervalSince(clearStartTime) < clearTimeout {
                let searchFieldAfterClear = app.searchFields.firstMatch
                let searchFieldValue = searchFieldAfterClear.value as? String ?? ""
                let placeholderValue = searchFieldAfterClear.placeholderValue ?? ""

                isCleared = searchFieldValue.isEmpty ||
                    searchFieldValue == placeholderValue ||
                    searchFieldValue == "Search news..." ||
                    searchFieldValue == "Search" ||
                    searchFieldValue == "Search..." ||
                    !searchFieldValue.lowercased().contains("apple") ||
                    searchForNews.exists ||
                    searchSubtitle.exists

                if isCleared {
                    break
                }
                wait(for: 0.3)
            }

            if !isCleared {
                clearSearchFieldIfNeeded(searchField)

                let searchFieldAfterClear = app.searchFields.firstMatch
                let searchFieldValue = searchFieldAfterClear.value as? String ?? ""
                let placeholderValue = searchFieldAfterClear.placeholderValue ?? ""

                isCleared = searchFieldValue.isEmpty ||
                    searchFieldValue == placeholderValue ||
                    searchFieldValue == "Search news..." ||
                    searchFieldValue == "Search" ||
                    searchFieldValue == "Search..." ||
                    !searchFieldValue.lowercased().contains("apple") ||
                    searchForNews.exists ||
                    searchSubtitle.exists
            }

            XCTAssertTrue(isCleared, "Search field should be cleared")
        }

        searchField.tap()
        searchField.typeText("test query")
        let cancelButton = app.buttons["Cancel"]

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
            wait(for: 0.5)
            XCTAssertFalse(app.keyboards.element.exists, "Keyboard should dismiss after cancel")
        }

        // --- Sort, Navigation, and Content States ---
        clearSearchFieldIfNeeded(searchField)
        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        wait(for: 3)

        let segmentedControl = app.segmentedControls.firstMatch

        if segmentedControl.exists {
            let segments = segmentedControl.buttons
            if segments.count > 1 {
                segments.element(boundBy: 1).tap()
                wait(for: 2)
            }
        }

        XCTAssertTrue(searchField.exists, "Search view should remain functional")

        let articleCardsForNavigation = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCardsForNavigation.count > 0 {
            articleCardsForNavigation.firstMatch.tap()
            wait(for: 1)

            let backButton = app.navigationBars.buttons.firstMatch
            let didNavigate = backButton.waitForExistence(timeout: 5) && !searchField.isHittable

            if didNavigate {
                backButton.tap()
                wait(for: 1)
                XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search")
            }
        }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
            scrollView.swipeUp()
            wait(for: 2)
        }

        XCTAssertTrue(searchField.exists, "Search should remain functional after scrolling")

        let clearButtonForNoResults = app.searchFields.buttons["Clear text"]
        if clearButtonForNoResults.exists {
            clearButtonForNoResults.tap()
        }

        searchField.tap()
        searchField.typeText("xyzqwerty123456789unlikely")
        submitSearch()

        wait(for: 3)

        let noResultsTextAfter = app.staticTexts["No Results Found"]
        let errorTextAfter = app.staticTexts["Search Failed"]

        let hasResponse = noResultsTextAfter.exists || errorTextAfter.exists ||
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'")).count > 0

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

        wait(for: 1)
        dismissKeyboard()

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        wait(for: 1)

        navigateToSearchTab()
        wait(for: 0.5)

        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search view")
    }
}
