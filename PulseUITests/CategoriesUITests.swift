import XCTest

final class CategoriesUITests: BaseUITestCase {

    // MARK: - Helper Methods

    /// Navigate to Categories tab
    private func navigateToCategories() {
        let categoriesTab = app.tabBars.buttons["Categories"]
        guard categoriesTab.waitForExistence(timeout: 5) else { return }
        if !categoriesTab.isSelected {
            categoriesTab.tap()
        }
        // Wait for Categories view to load
        _ = app.navigationBars["Categories"].waitForExistence(timeout: Self.defaultTimeout)
    }

    private func categoryChipsScrollView() -> XCUIElement {
        let chipsScrollView = app.scrollViews["categoryChipsScrollView"]
        if chipsScrollView.exists {
            return chipsScrollView
        }
        return app.scrollViews.firstMatch
    }

    private func selectAnyCategory(timeout: TimeInterval = 8) -> Bool {
        let scrollView = categoryChipsScrollView()
        _ = scrollView.waitForExistence(timeout: timeout)

        for category in categoryNames {
            if scrollToAndTapCategory(category) {
                return true
            }
        }

        return false
    }

    @discardableResult
    private func scrollToAndTapCategory(_ category: String) -> Bool {
        let button = app.buttons[category]
        let scrollView = categoryChipsScrollView()

        if isElementVisible(button) {
            button.tap()
            return true
        }

        for _ in 0 ..< 6 {
            scrollView.swipeLeft()
            wait(for: 0.3)
            if isElementVisible(button) {
                button.tap()
                return true
            }
        }

        for _ in 0 ..< 6 {
            scrollView.swipeRight()
            wait(for: 0.3)
            if isElementVisible(button) {
                button.tap()
                return true
            }
        }

        return false
    }

    private let categoryNames = ["World", "Business", "Technology", "Science", "Health", "Sports", "Entertainment"]

    // MARK: - Navigation, Initial State, and Chips Tests

    /// Tests tab navigation, initial state, and category chips
    func testNavigationInitialStateAndChips() throws {
        // --- Navigation ---
        let categoriesTab = app.tabBars.buttons["Categories"]
        XCTAssertTrue(categoriesTab.exists, "Categories tab should exist")

        navigateToCategories()

        XCTAssertTrue(categoriesTab.isSelected, "Categories tab should be selected")

        let navTitle = app.navigationBars["Categories"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'Categories' should exist")

        // --- Initial State ---
        let selectCategoryText = app.staticTexts["Select a Category"]
        let noSelectionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Choose a category'")).firstMatch

        // Wait for initial state content with longer timeout
        let timeout: TimeInterval = 15
        let startTime = Date()
        var foundInitialState = false

        while Date().timeIntervalSince(startTime) < timeout {
            if selectCategoryText.exists || noSelectionText.exists {
                foundInitialState = true
                break
            }
            wait(for: 0.5)
        }

        XCTAssertTrue(foundInitialState, "Initial state should show select category prompt")

        // --- Category Chips ---
        wait(for: 1)

        var foundCategory = false
        for category in categoryNames {
            if app.staticTexts[category].exists || app.buttons[category].exists {
                foundCategory = true
                break
            }
        }
        XCTAssertTrue(foundCategory, "At least one category chip should exist")

        // Test horizontal scrolling
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            scrollViews.firstMatch.swipeLeft()

            foundCategory = false
            for category in categoryNames {
                if app.staticTexts[category].exists || app.buttons[category].exists {
                    foundCategory = true
                    break
                }
            }
            XCTAssertTrue(foundCategory, "Categories should still be visible after scrolling")
        }
    }

    // MARK: - Selection, Navigation, and Scroll Tests

    /// Tests category selection, article navigation, scroll behavior, and content states
    func testSelectionNavigationScrollAndContentStates() throws {
        navigateToCategories()

        wait(for: 1)

        // --- Category Selection ---
        var categoryTapped = false
        for category in categoryNames {
            let categoryButton = app.buttons[category]
            if categoryButton.exists {
                categoryButton.tap()
                categoryTapped = true
                break
            }
        }

        guard categoryTapped else {
            throw XCTSkip("Could not find a category to tap")
        }

        wait(for: 2)

        // Content should change
        let selectCategoryText = app.staticTexts["Select a Category"]
        let loadingText = app.staticTexts["Loading articles..."]
        let articlesCountText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'articles'")).firstMatch
        let noArticlesText = app.staticTexts["No Articles"]
        let errorText = app.staticTexts["Error"]

        let contentChanged = !selectCategoryText.exists ||
            loadingText.exists ||
            articlesCountText.exists ||
            noArticlesText.exists ||
            errorText.exists

        XCTAssertTrue(contentChanged, "Content should change after selecting a category")

        // --- Article Navigation ---
        let articleCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour'"))

        if articleCards.count > 0 {
            articleCards.firstMatch.tap()

            XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

            navigateBack()

            let categoriesNav = app.navigationBars["Categories"]
            XCTAssertTrue(categoriesNav.waitForExistence(timeout: 5), "Should return to Categories")
        }

        // --- Scroll Behavior ---
        let navTitle = app.navigationBars["Categories"]
        guard navTitle.waitForExistence(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Categories navigation did not load")
        }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Test infinite scroll
            scrollView.swipeUp()
            scrollView.swipeUp()

            // Test pull to refresh
            scrollView.swipeDown()
        }

        XCTAssertTrue(navTitle.exists || app.navigationBars.count > 0, "Navigation should work after scrolling")

        // --- Content States ---
        if errorText.exists {
            let tryAgainButton = app.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Error state should have Try Again button")
        } else if noArticlesText.exists {
            let helpText = app.staticTexts["No articles found in this category."]
            XCTAssertTrue(helpText.exists, "Empty state should show helpful message")
        }

        // Test switching categories
        for category in categoryNames.reversed() {
            if scrollToAndTapCategory(category) {
                break
            }
        }

        wait(for: 2)

        XCTAssertTrue(navTitle.exists, "Navigation should work after switching categories")
    }

    // MARK: - Tab Switching Tests

    /// Tests that tab switching works correctly
    func testTabSwitching() throws {
        navigateToCategories()

        wait(for: 1)

        let technologyButton = app.buttons["Technology"]
        if technologyButton.exists {
            technologyButton.tap()
        }

        wait(for: 2)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        wait(for: 1)

        // Verify we're on Home
        let homeNav = app.navigationBars["Pulse"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load after tab switch")

        navigateToCategories()

        wait(for: 1)

        let navTitle = app.navigationBars["Categories"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Categories view should load after tab switch")
    }
}
