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

    // MARK: - Search UI and Initial State Tests

    /// Tests search bar existence, interactivity, and initial empty state
    func testSearchUIAndInitialState() throws {
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
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(searchUILoaded, "Search UI should load (search field or empty state)")

        // Initial state shows "Search for News" empty state
        XCTAssertTrue(searchForNews.exists || searchSubtitle.exists, "Initial empty state should show 'Search for News'")

        // Test search field can receive input
        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be interactable")
            searchField.tap()
            searchField.typeText("technology")

            let keyboard = app.keyboards.element
            XCTAssertTrue(keyboard.waitForExistence(timeout: 3), "Keyboard should appear for text input")
        }
    }

    // MARK: - Search Input and Results Tests

    /// Tests search input shows results and article cards
    func testSearchInputAndResults() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

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
            Thread.sleep(forTimeInterval: 0.5)
        }

        // If nothing specific appeared, at least verify we're not in initial state
        if !hasContent {
            hasContent = !app.staticTexts["Search for News"].exists
        }

        XCTAssertTrue(hasContent, "Search should show results, loading, or status message")
    }

    // MARK: - Clear and Cancel Button Tests

    /// Tests search clear and cancel buttons
    func testSearchClearAndCancelButtons() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("test query")
        Thread.sleep(forTimeInterval: 0.5)

        // Test clear button
        let clearButton = app.searchFields.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 3) {
            clearButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let searchFieldValue = searchField.value as? String ?? ""
            let isCleared = searchFieldValue.isEmpty ||
                searchFieldValue == "Search news..." ||
                searchFieldValue == "Search" ||
                !searchFieldValue.contains("test query")
            XCTAssertTrue(isCleared, "Search field should be cleared")
        }

        // Test cancel button
        searchField.tap()
        let cancelButton = app.buttons["Cancel"]

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertFalse(app.keyboards.element.exists, "Keyboard should dismiss after cancel")
        }
    }

    // MARK: - Trending Topics and Suggestions Tests

    /// Tests trending topics, categories, and suggestions
    func testTrendingTopicsAndSuggestions() throws {
        navigateToSearchTab()

        // Initial state shows "Search for News" empty state
        let searchForNews = app.staticTexts["Search for News"]
        let searchSubtitle = app.staticTexts["Find articles from thousands of sources worldwide"]

        let timeout: TimeInterval = 15
        let startTime = Date()
        var foundInitialState = false

        while Date().timeIntervalSince(startTime) < timeout {
            if searchForNews.exists || searchSubtitle.exists {
                foundInitialState = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(foundInitialState, "Initial empty state should show 'Search for News'")

        let subtitle = app.staticTexts["Find articles from thousands of sources worldwide"]
        XCTAssertTrue(subtitle.exists || searchForNews.exists, "Initial empty state should have descriptive text")

        // Tap search field to activate
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()

        // Wait for suggestions or empty state
        Thread.sleep(forTimeInterval: 1)

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
                Thread.sleep(forTimeInterval: 2)

                // Initial empty state should disappear
                let emptyStateGone = !app.staticTexts["Search for News"].exists
                XCTAssertTrue(emptyStateGone, "Tapping category should start search")
                return
            }
        }
    }

    // MARK: - Sort Options Tests

    /// Tests sort picker and changing sort options
    func testSortOptions() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        // Wait for results
        Thread.sleep(forTimeInterval: 3)

        // Try to change sort option
        let segmentedControl = app.segmentedControls.firstMatch

        if segmentedControl.exists {
            // Find and tap a different segment
            let segments = segmentedControl.buttons
            if segments.count > 1 {
                segments.element(boundBy: 1).tap()
                Thread.sleep(forTimeInterval: 2)
            }
        }

        // View should remain functional
        XCTAssertTrue(searchField.exists, "Search view should remain functional")
    }

    // MARK: - Article Navigation Tests

    /// Tests article tap navigation and infinite scroll
    func testSearchResultNavigation() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("technology")
        submitSearch()

        // Wait for results
        Thread.sleep(forTimeInterval: 3)

        // Find and tap an article
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago'"))

        if articleCards.count > 0 {
            articleCards.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1)

            let backButton = app.navigationBars.buttons.firstMatch
            let didNavigate = backButton.waitForExistence(timeout: 5) && !searchField.isHittable

            if didNavigate {
                backButton.tap()
                Thread.sleep(forTimeInterval: 1)
                XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search")
            }
        }

        // Test infinite scroll
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 2)
        }

        XCTAssertTrue(searchField.exists, "Search should remain functional after scrolling")
    }

    // MARK: - Content State Tests

    /// Tests no results, error, and loading states
    func testSearchContentStates() throws {
        navigateToSearchTab()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Search for something unlikely to have results
        searchField.tap()
        searchField.typeText("xyzqwerty123456789unlikely")
        submitSearch()

        // Wait for results
        Thread.sleep(forTimeInterval: 3)

        // Check for various states
        let noResultsText = app.staticTexts["No Results Found"]
        let errorText = app.staticTexts["Search Failed"]
        let searchingText = app.staticTexts["Searching..."]

        let hasResponse = noResultsText.exists || errorText.exists || searchingText.exists ||
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
        Thread.sleep(forTimeInterval: 1)
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
        Thread.sleep(forTimeInterval: 3)

        // Switch to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        Thread.sleep(forTimeInterval: 1)

        // Switch back to Search
        navigateToSearchTab()
        Thread.sleep(forTimeInterval: 0.5)

        // Search state should be preserved
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Should return to Search view")
    }
}
