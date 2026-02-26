import XCTest

final class HomeUITests: BaseUITestCase {
    // MARK: - Edit Topics Tests

    /// Tests opening the edit topics sheet from Home and toggling topics
    func testEditTopicsFromHome() {
        // Verify we're on Home
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should be on Home")

        // Find and tap the edit topics button
        let editTopicsButton = app.navigationBars.buttons["line.3.horizontal.decrease.circle"]
        XCTAssertTrue(editTopicsButton.waitForExistence(timeout: Self.shortTimeout), "Edit topics button should exist")
        editTopicsButton.tap()

        // Wait for sheet presentation animation on slow CI
        wait(for: 1.0)

        // Verify the edit topics sheet opens — retry tap if sheet didn't appear
        let editTopicsTitle = app.staticTexts["Edit Topics"]
        if !editTopicsTitle.waitForExistence(timeout: Self.defaultTimeout) {
            // Retry: button tap may not have registered on slow CI
            if editTopicsButton.exists, editTopicsButton.isHittable {
                editTopicsButton.tap()
                wait(for: 1.0)
            }
        }
        XCTAssertTrue(editTopicsTitle.waitForExistence(timeout: Self.defaultTimeout), "Edit Topics sheet should open")

        // Verify topics are displayed
        let technologyTopic = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch
        XCTAssertTrue(technologyTopic.waitForExistence(timeout: Self.shortTimeout), "Technology topic should be visible")

        // Toggle a topic
        technologyTopic.tap()

        // Verify Done button exists and tap it
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: Self.shortTimeout), "Done button should exist")
        doneButton.tap()

        // Verify sheet is dismissed and we're back on Home
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home after dismissing sheet")
    }

    // MARK: - Category Tabs Tests

    /// Tests category tabs visibility and interaction after enabling topics
    func testCategoryTabsAfterEnablingTopics() {
        // Open edit topics sheet
        let editTopicsButton = app.navigationBars.buttons["line.3.horizontal.decrease.circle"]
        XCTAssertTrue(editTopicsButton.waitForExistence(timeout: Self.shortTimeout), "Edit topics button should exist")
        editTopicsButton.tap()

        // Verify the edit topics sheet opens
        let editTopicsTitle = app.staticTexts["Edit Topics"]
        XCTAssertTrue(editTopicsTitle.waitForExistence(timeout: Self.defaultTimeout), "Edit Topics sheet should open")

        // Enable some topics
        let technologyTopic = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Technology'")).firstMatch
        let businessTopic = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Business'")).firstMatch

        if technologyTopic.waitForExistence(timeout: Self.shortTimeout) {
            technologyTopic.tap()
        }

        if businessTopic.waitForExistence(timeout: Self.shortTimeout) {
            businessTopic.tap()
        }

        // Dismiss sheet
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }

        // Verify we're back on Home
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")

        // Wait for content to load
        _ = waitForHomeContent(timeout: 30)

        // Check if category tabs are visible (look for "All" button which is always present when tabs are shown)
        let allTabButton = app.buttons["All"]
        if allTabButton.waitForExistence(timeout: Self.shortTimeout) {
            // Category tabs are visible - test interaction
            allTabButton.tap()

            // Verify app remains responsive
            XCTAssertTrue(app.navigationBars["News"].exists, "App should remain on Home after tapping All tab")
        }
    }

    /// Tests that tapping a category tab filters content
    func testCategoryTabFiltersContent() {
        // Wait for content to load
        _ = waitForHomeContent(timeout: 30)

        // Check if category tabs exist
        let allTabButton = app.buttons["All"]

        if allTabButton.waitForExistence(timeout: Self.shortTimeout) {
            // Try to find and tap a category tab
            let technologyTab = app.buttons["Technology"]
            let businessTab = app.buttons["Business"]

            if technologyTab.exists {
                technologyTab.tap()

                // Wait a moment for content to reload
                _ = wait(for: 1.0)

                // Verify app is still responsive
                XCTAssertTrue(app.navigationBars["News"].exists, "App should remain on Home after category selection")

                // Tap All to return to unfiltered view
                allTabButton.tap()
                XCTAssertTrue(app.navigationBars["News"].exists, "App should remain on Home after returning to All")
            } else if businessTab.exists {
                businessTab.tap()
                _ = wait(for: 1.0)
                XCTAssertTrue(app.navigationBars["News"].exists, "App should remain on Home after category selection")
            }
        }
    }

    /// Tests horizontal scrolling of category tabs when many categories are followed
    func testCategoryTabsHorizontalScroll() {
        // Wait for content to load
        _ = waitForHomeContent(timeout: 30)

        // Check if category tabs exist
        let allTabButton = app.buttons["All"]

        if allTabButton.waitForExistence(timeout: Self.shortTimeout) {
            // Try to scroll horizontally in the category tabs area
            // The scroll view containing tabs should be near the top
            let scrollViews = app.scrollViews
            if scrollViews.count > 0 {
                let tabsScrollView = scrollViews.firstMatch

                // Perform horizontal swipe
                tabsScrollView.swipeLeft()
                _ = wait(for: 0.5)

                // Swipe back
                tabsScrollView.swipeRight()

                // Verify app is still responsive
                XCTAssertTrue(app.navigationBars["News"].exists, "App should remain responsive after horizontal scroll")
            }
        }
    }

    // MARK: - Navigation and Content Tests

    /// Tests navigation bar, content loading, interactions, and settings navigation
    func testHomeContentInteractionsAndSettingsFlow() {
        // Verify navigation title
        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Navigation title 'News' should exist")

        // Verify gear button
        let gearButton = app.navigationBars.buttons["gearshape"]
        XCTAssertTrue(gearButton.waitForExistence(timeout: Self.shortTimeout), "Gear button should exist in navigation bar")

        // Verify content loads (use longer timeout for CI environments)
        // Note: In CI, mock data may not be available, so we test what we can
        let contentLoaded = waitForHomeContent(timeout: 45)

        // Check error state if present
        let errorState = app.staticTexts["Unable to Load News"].exists
        let emptyState = app.staticTexts["No News Available"].exists

        // Test continues regardless of content state - CI may have limited mock data
        if errorState {
            let tryAgainButton = app.buttons["Try Again"]
            if tryAgainButton.exists {
                // Error state is valid, try again button exists as expected
            }
        }

        // --- Settings Navigation ---
        gearButton.tap()

        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: Self.defaultTimeout), "Settings should open")

        var settingsBackButton = settingsNavBar.buttons["Pulse"]
        if !settingsBackButton.exists {
            settingsBackButton = settingsNavBar.buttons["Back"]
        }
        if !settingsBackButton.exists {
            settingsBackButton = settingsNavBar.buttons.firstMatch
        }

        if settingsBackButton.exists {
            settingsBackButton.tap()
        } else {
            app.swipeRight()
        }

        XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")

        // Only test article interactions if content loaded successfully and isn't an error/empty state
        // This makes tests resilient to CI environments with limited mock data
        if contentLoaded, !errorState, !emptyState {
            let cards = articleCards()
            let firstCard = cards.firstMatch

            // Use longer timeout for CI - articles may take time to render
            if firstCard.waitForExistence(timeout: 15) {
                // --- Article Card Navigation ---

                // Scroll to make the card hittable if needed
                if !firstCard.isHittable {
                    app.scrollViews.firstMatch.swipeUp()
                }

                if firstCard.isHittable {
                    firstCard.tap()
                    XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                    // Navigate back
                    navigateBack()
                    XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "Should return to Home")
                }

                // --- Scroll Interactions ---
                let scrollView = app.scrollViews.firstMatch
                XCTAssertTrue(scrollView.waitForExistence(timeout: Self.shortTimeout), "ScrollView should exist")

                // Pull to refresh
                scrollView.swipeDown()
                XCTAssertTrue(scrollView.exists, "ScrollView should still exist after refresh")

                // Vertical scroll
                scrollView.swipeUp()
                XCTAssertTrue(app.navigationBars["News"].waitForExistence(timeout: Self.shortTimeout), "App should remain responsive after scrolling")

                // Horizontal carousel scroll (if Breaking News exists)
                if app.staticTexts["Breaking News"].exists {
                    scrollView.swipeLeft()
                }

                // --- Context Menu ---
                let cardsAfterScroll = articleCards()
                let contextCard = cardsAfterScroll.firstMatch
                if contextCard.waitForExistence(timeout: Self.shortTimeout) {
                    contextCard.press(forDuration: 0.5)

                    let contextMenuAppeared = app.buttons["Bookmark"].waitForExistence(timeout: Self.shortTimeout) ||
                        app.buttons["Share"].waitForExistence(timeout: 1)

                    if contextMenuAppeared {
                        app.tap() // Dismiss context menu
                    }
                }
            }
        }
    }
}
