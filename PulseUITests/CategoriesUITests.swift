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

    private func selectAnyCategory(timeout: TimeInterval = 5) -> Bool {
        _ = categoryChipsScrollView().waitForExistence(timeout: timeout)

        // Try visible categories first (no scrolling needed)
        for category in categoryNames {
            let button = app.buttons[category]
            if button.exists, isElementVisible(button) {
                button.tap()
                return true
            }
        }

        // Quick scroll and try first visible
        let scrollView = categoryChipsScrollView()
        scrollView.swipeLeft()
        for category in categoryNames {
            let button = app.buttons[category]
            if button.exists, isElementVisible(button) {
                button.tap()
                return true
            }
        }
        return false
    }

    @discardableResult
    private func scrollToAndTapCategory(_ category: String) -> Bool {
        let button = app.buttons[category]

        // Check if already visible
        if button.exists, isElementVisible(button) {
            button.tap()
            return true
        }

        // Single scroll attempt in each direction
        let scrollView = categoryChipsScrollView()
        scrollView.swipeRight()
        // Check existence immediately without aggressive timeout
        if button.exists, isElementVisible(button) {
            button.tap()
            return true
        }

        for _ in 0..<3 {
            scrollView.swipeLeft()
            if button.exists, isElementVisible(button) {
                button.tap()
                return true
            }
        }
        return false
    }

    private let categoryNames = ["World", "Business", "Technology", "Science", "Health", "Sports", "Entertainment"]

    // MARK: - Combined Flow Test

    /// Tests categories navigation, selection, content states, and tab switching
    func testCategoriesFlow() throws {
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

        let foundInitialState = waitForAny([selectCategoryText, noSelectionText], timeout: Self.defaultTimeout)

        XCTAssertTrue(foundInitialState, "Initial state should show select category prompt")

        // --- Category Chips ---
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

        // --- Selection, Content, and Scroll ---
        let categoryTapped = selectAnyCategory()
        XCTAssertTrue(categoryTapped, "Could not find a category to tap")

        if categoryTapped {
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
            let cards = articleCards()

            if cards.count > 0 {
                cards.firstMatch.tap()

                XCTAssertTrue(waitForArticleDetail(), "Should navigate to article detail")

                navigateBack()

                let categoriesNav = app.navigationBars["Categories"]
                XCTAssertTrue(categoriesNav.waitForExistence(timeout: 5), "Should return to Categories")
            }

            // --- Scroll Behavior ---
            if navTitle.waitForExistence(timeout: Self.defaultTimeout) {
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }

                XCTAssertTrue(navTitle.exists || app.navigationBars.count > 0, "Navigation should work after scrolling")
            }

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

            XCTAssertTrue(navTitle.waitForExistence(timeout: Self.defaultTimeout), "Navigation should work after switching categories")
        }

        // --- Tab Switching ---
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: Self.shortTimeout), "Home tab should exist")
        homeTab.tap()

        let homeNav = app.navigationBars["News"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: Self.defaultTimeout), "Home should load after tab switch")

        navigateToCategories()

        let navTitleAfterSwitch = app.navigationBars["Categories"]
        XCTAssertTrue(navTitleAfterSwitch.waitForExistence(timeout: Self.defaultTimeout), "Categories view should load after tab switch")
    }
}
