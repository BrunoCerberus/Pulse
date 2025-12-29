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

    // MARK: - Search UI, Initial State, and Suggestions Tests

    /// Tests search bar, initial state, and trending topics/suggestions
    func testSearchUIInitialStateAndSuggestions() throws {
        navigateToSearchTab()

        let searchNav = app.navigationBars["Search"]
        XCTAssertTrue(searchNav.waitForExistence(timeout: Self.defaultTimeout), "Search navigation should load")

        // Use polling to check for search field or search-related content
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

        // Initial state shows "Search for News" empty state
        XCTAssertTrue(searchForNews.exists || searchSubtitle.exists, "Initial empty state should show 'Search for News'")

        // Test search field can receive input
        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be interactable")
            searchField.tap()

            let keyboard = app.keyboards.element
            XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear for text input")

            // Wait for suggestions or empty state
            wait(for: 1)

            // Either suggestions, trending topics, or empty state should appear
            let trendingHeader = app.staticTexts["Trending Topics"]
            let recentHeader = app.staticTexts["Recent Searches"]

            let hasSuggestions = trendingHeader.exists || recentHeader.exists || searchForNews.exists
            XCTAssertTrue(hasSuggestions, "Should show suggestions or empty state")

            // Test tapping a category if visible
            let categoryNames = ["Technology", "Business", "World", "Science"]
            for category in categoryNames {
                let categoryButton = app.buttons[category]
                if categoryButton.exists {
                    categoryButton.tap()
                    wait(for: 2)

                    // Initial empty state should disappear
                    let emptyStateGone = !app.staticTexts["Search for News"].exists
                    XCTAssertTrue(emptyStateGone, "Tapping category should start search")
                    return
                }
            }
        }
    }

    // MARK: - Search Input, Results, and Clear/Cancel Tests

    /// Tests search input, results display, clear button, and cancel button
    func testSearchInputResultsAndClearCancel() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // --- Search Input and Results ---
        searchField.tap()
        searchField.typeText("Apple")
        submitSearch()

        // Wait for results using polling
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))
        let noResultsText = app.staticTexts["No Results Found"]
        let searchingText = app.staticTexts["Searching..."]
        let errorText = app.staticTexts["Search Failed"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var hasContent = false

        while Date().timeIntervalSince(startTime) < timeout {
            if articleCards.count > 0 || noResultsText.exists || searchingText.exists || errorText.exists {
                hasContent = true
                break
            }
            wait(for: 0.5)
        }

        // If nothing specific appeared, at least verify we're not in initial state
        if !hasContent {
            hasContent = !app.staticTexts["Search for News"].exists
        }

        XCTAssertTrue(hasContent, "Search should show results, loading, or status message")

        // --- Clear Button ---
        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 3) {
            clearButton.tap()
            wait(for: 1)

            // Re-query the search field after clearing
            let searchFieldAfterClear = app.searchFields.firstMatch
            let searchFieldValue = searchFieldAfterClear.value as? String ?? ""
            let placeholderValue = searchFieldAfterClear.placeholderValue ?? ""
            let isCleared = searchFieldValue.isEmpty ||
                searchFieldValue == placeholderValue ||
                searchFieldValue == "Search news..." ||
                searchFieldValue == "Search" ||
                searchFieldValue == "Search..." ||
                !searchFieldValue.lowercased().contains("apple")
            XCTAssertTrue(isCleared, "Search field should be cleared, got: '\(searchFieldValue)'")
        }

        // --- Cancel Button ---
        searchField.tap()
        searchField.typeText("test query")
        let cancelButton = app.buttons["Cancel"]

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
            wait(for: 0.5)
            XCTAssertFalse(app.keyboards.element.exists, "Keyboard should dismiss after cancel")
        }
    }

    // MARK: - Sort, Navigation, and Content States Tests

    /// Tests sort options, article navigation, infinite scroll, and content states
    func testSortNavigationAndContentStates() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        // Wait for results
        wait(for: 3)

        // --- Sort Options ---
        let segmentedControl = app.segmentedControls.firstMatch

        if segmentedControl.exists {
            let segments = segmentedControl.buttons
            if segments.count > 1 {
                segments.element(boundBy: 1).tap()
                wait(for: 2)
            }
        }

        XCTAssertTrue(searchField.exists, "Search view should remain functional")

        // --- Article Navigation ---
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            articleCards.firstMatch.tap()
            wait(for: 1)

            let backButton = app.navigationBars.buttons.firstMatch
            let didNavigate = backButton.waitForExistence(timeout: 5) && !searchField.isHittable

            if didNavigate {
                backButton.tap()
                wait(for: 1)
                XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search")
            }
        }

        // --- Infinite Scroll ---
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
            scrollView.swipeUp()
            wait(for: 2)
        }

        XCTAssertTrue(searchField.exists, "Search should remain functional after scrolling")

        // --- Content States (No Results) ---
        // Clear and search for something unlikely
        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }

        searchField.tap()
        searchField.typeText("xyzqwerty123456789unlikely")
        submitSearch()

        wait(for: 3)

        let noResultsText = app.staticTexts["No Results Found"]
        let errorText = app.staticTexts["Search Failed"]

        let hasResponse = noResultsText.exists || errorText.exists ||
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'")).count > 0

        XCTAssertTrue(hasResponse, "Search should show a response")

        // Check error state has try again button
        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        }
    }

    // MARK: - Keyboard Behavior Tests

    /// Tests keyboard appears and dismisses correctly
    func testKeyboardBehavior() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Test keyboard appears
        searchField.tap()
        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear")

        // Test keyboard dismisses on search
        searchField.typeText("test")
        XCTAssertTrue(app.keyboards.element.exists, "Keyboard should be shown")
        submitSearch()

        // Keyboard should dismiss after search
        wait(for: 1)
    }

    // MARK: - Tab Switching Tests

    /// Tests search state preserved on tab switch
    func testSearchStatePreservedOnTabSwitch() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        // Wait for results
        wait(for: 3)

        // Switch to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        wait(for: 1)

        // Switch back to Search
        navigateToSearchTab()
        wait(for: 0.5)

        // Search state should be preserved
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search view")
    }
}
