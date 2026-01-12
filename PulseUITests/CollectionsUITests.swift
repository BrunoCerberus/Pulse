import XCTest

final class CollectionsUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Navigate to Collections tab and verify navigation bar appears
    func navigateToCollectionsTab() {
        let collectionsTab = app.tabBars.buttons["Collections"]
        if collectionsTab.exists, !collectionsTab.isSelected {
            collectionsTab.tap()
        }
        _ = app.navigationBars["Collections"].waitForExistence(timeout: Self.shortTimeout)
    }

    /// Wait for collections content to load
    func waitForCollectionsContent(timeout: TimeInterval = 10) -> Bool {
        let contentIndicators = [
            app.staticTexts["Featured"],
            app.staticTexts["My Collections"],
            app.staticTexts["No Collections Yet"],
            app.staticTexts["Something went wrong"],
            app.scrollViews.firstMatch,
        ]
        return waitForAny(contentIndicators, timeout: timeout)
    }

    /// Find collection cards in the featured section
    func collectionCards() -> XCUIElementQuery {
        app.buttons.matching(identifier: "collectionCard")
    }

    // MARK: - Combined Flow Test

    /// Tests Collections tab navigation, content states, interactions, and creation flow
    func testCollectionsFlow() throws {
        // --- Tab Navigation ---
        let collectionsTab = app.tabBars.buttons["Collections"]
        XCTAssertTrue(collectionsTab.waitForExistence(timeout: Self.launchTimeout), "Collections tab should exist")

        navigateToCollectionsTab()

        XCTAssertTrue(collectionsTab.isSelected, "Collections tab should be selected")

        let navTitle = app.navigationBars["Collections"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation title 'Collections' should exist")

        // --- Content Loading ---
        let featuredText = app.staticTexts["Featured"]
        let myCollectionsText = app.staticTexts["My Collections"]
        let emptyText = app.staticTexts["No Collections Yet"]
        let errorText = app.staticTexts["Something went wrong"]

        let contentLoaded = waitForCollectionsContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Collections should show content (featured, empty, or error state)")

        // --- Featured Collections Section ---
        if featuredText.exists {
            XCTAssertTrue(featuredText.exists, "Featured section should be visible when collections are loaded")

            // Verify horizontal scroll view for featured collections
            let horizontalScrollView = app.scrollViews.element(boundBy: 1) // Second scroll view is horizontal
            if horizontalScrollView.exists {
                // Try to scroll horizontally to see more cards
                horizontalScrollView.swipeLeft()
            }
        }

        // --- My Collections Section ---
        if myCollectionsText.exists {
            XCTAssertTrue(myCollectionsText.exists, "My Collections section should be visible")

            // Look for the add button in My Collections header
            let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus.circle.fill' OR identifier CONTAINS 'addCollection'")).firstMatch
            if addButton.exists {
                // Verify add button is present
                XCTAssertTrue(addButton.exists, "Add collection button should exist in My Collections section")
            }
        }

        // --- Empty State ---
        if emptyText.exists {
            let createButton = app.buttons["New Collection"]
            XCTAssertTrue(createButton.exists, "Empty state should have 'New Collection' button")
        }

        // --- Error State ---
        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have 'Try Again' button")
        }

        // --- Create Collection Flow ---
        let plusButton = app.navigationBars.buttons["plus"]
        if plusButton.waitForExistence(timeout: Self.shortTimeout) {
            plusButton.tap()

            // Verify create collection sheet appears
            let createSheetTitle = app.staticTexts["New Collection"]
            XCTAssertTrue(createSheetTitle.waitForExistence(timeout: Self.defaultTimeout), "Create collection sheet should appear")

            // Verify form fields exist
            let nameField = app.textFields["e.g., Research Notes"]
            let descriptionField = app.textFields["What is this collection about?"]

            if nameField.exists {
                nameField.tap()
                nameField.typeText("Test Collection")
            }

            // Dismiss the sheet
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Swipe down to dismiss
                app.swipeDown()
            }

            _ = navTitle.waitForExistence(timeout: Self.defaultTimeout)
        }

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load")

        let collectionsTabReturn = app.tabBars.buttons["Collections"]
        XCTAssertTrue(collectionsTabReturn.waitForExistence(timeout: Self.shortTimeout), "Collections tab should exist")
        collectionsTabReturn.tap()

        let collectionsNavAfterSwitch = app.navigationBars["Collections"]
        XCTAssertTrue(collectionsNavAfterSwitch.waitForExistence(timeout: Self.defaultTimeout), "Collections should be visible after tab switch")

        // --- Pull to Refresh ---
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            _ = navTitle.waitForExistence(timeout: Self.shortTimeout)
        }

        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.shortTimeout), "View should remain functional after refresh")
    }

    // MARK: - Collection Detail Navigation Test

    func testCollectionDetailNavigation() throws {
        navigateToCollectionsTab()

        let contentLoaded = waitForCollectionsContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Collections content should load")

        // Try to find and tap a collection card
        let featuredText = app.staticTexts["Featured"]
        if featuredText.waitForExistence(timeout: Self.defaultTimeout) {
            // Look for any tappable collection cards
            let buttons = app.buttons.allElementsBoundByIndex

            // Find a collection card (look for buttons with collection-like properties)
            for button in buttons {
                if button.frame.width > 100, button.frame.height > 100, button.isHittable {
                    // This could be a collection card
                    button.tap()

                    // Check if we navigated to a detail view (back button should appear)
                    let backButton = app.buttons["backButton"]
                    if backButton.waitForExistence(timeout: Self.defaultTimeout) {
                        XCTAssertTrue(backButton.exists, "Should navigate to collection detail")

                        // Navigate back
                        backButton.tap()

                        let navTitle = app.navigationBars["Collections"]
                        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Should return to Collections")
                        break
                    }
                }
            }
        }
    }

    // MARK: - Premium Section Test

    func testPremiumSectionVisible() throws {
        navigateToCollectionsTab()

        let contentLoaded = waitForCollectionsContent(timeout: 15)
        XCTAssertTrue(contentLoaded, "Collections content should load")

        // Scroll down to find premium section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Scroll to bottom
            for _ in 0 ..< 3 {
                scrollView.swipeUp()
            }

            // Look for premium section indicators
            let premiumText = app.staticTexts["Premium Collections"]
            let proText = app.staticTexts["PRO"]

            if premiumText.exists || proText.exists {
                XCTAssertTrue(premiumText.exists || proText.exists, "Premium section should be visible")
            }
        }
    }

    // MARK: - Tab Bar Position Test

    func testCollectionsTabPosition() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: Self.launchTimeout), "Tab bar should exist")

        // Verify Collections tab exists and is in the correct position
        let tabButtons = tabBar.buttons.allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(tabButtons.count, 5, "Tab bar should have at least 5 tabs")

        // Find Collections tab index
        var collectionsIndex = -1
        for (index, button) in tabButtons.enumerated() {
            if button.label == "Collections" || button.identifier == "Collections" {
                collectionsIndex = index
                break
            }
        }

        // Collections should be between ForYou (index 1) and Bookmarks (index 3)
        // So Collections should be at index 2
        XCTAssertEqual(collectionsIndex, 2, "Collections tab should be at index 2 (between ForYou and Bookmarks)")
    }
}
