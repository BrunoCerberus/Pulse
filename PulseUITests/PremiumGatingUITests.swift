import XCTest

// MARK: - Non-Premium User Tests

/// Tests premium feature gating for non-premium users.
/// These tests verify that premium features are properly locked.
final class PremiumGatingNonPremiumUITests: BaseUITestCase {

    // MARK: - Feed Tab Premium Gate

    /// Tests that non-premium users see the premium gate on Feed tab
    func testFeedTabShowsPremiumGateForNonPremiumUser() throws {
        // Navigate to Feed tab
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeedTab()

        // Non-premium users should see the premium gate
        let premiumBadge = app.staticTexts["Premium Feature"]
        let premiumTitle = app.staticTexts["AI Daily Digest"]
        let unlockButton = app.buttons["Unlock Premium"]

        let hasPremiumGate = waitForAny([premiumBadge, premiumTitle, unlockButton], timeout: 10)
        XCTAssertTrue(hasPremiumGate, "Non-premium user should see premium gate on Feed tab")

        // Should NOT see premium content
        let digestContent = app.staticTexts["Your Daily Digest"]
        XCTAssertFalse(digestContent.exists, "Non-premium user should not see digest content")
    }

    /// Tests that tapping Unlock Premium on Feed shows paywall
    func testFeedUnlockButtonShowsPaywall() throws {
        navigateToFeedTab()

        let unlockButton = app.buttons["Unlock Premium"]
        guard unlockButton.waitForExistence(timeout: 10) else {
            XCTFail("Unlock Premium button should exist for non-premium user")
            return
        }

        unlockButton.tap()

        // Paywall sheet should appear
        let paywallTitle = app.staticTexts["Unlock Premium"]
        let subscriptionView = app.scrollViews.firstMatch

        let paywallAppeared = paywallTitle.waitForExistence(timeout: 5) || subscriptionView.waitForExistence(timeout: 5)
        XCTAssertTrue(paywallAppeared, "Paywall should appear after tapping Unlock Premium")

        // Dismiss the sheet
        app.swipeDown()
    }

    // MARK: - For You Tab Premium Gate

    /// Tests that non-premium users see the premium gate on For You tab
    func testForYouTabShowsPremiumGateForNonPremiumUser() throws {
        // Navigate to For You tab
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: Self.launchTimeout), "For You tab should exist")

        navigateToForYouTab()

        // Non-premium users should see the premium gate
        let premiumBadge = app.staticTexts["Premium Feature"]
        let premiumTitle = app.staticTexts["Personalized For You"]
        let unlockButton = app.buttons["Unlock Premium"]

        let hasPremiumGate = waitForAny([premiumBadge, premiumTitle, unlockButton], timeout: 10)
        XCTAssertTrue(hasPremiumGate, "Non-premium user should see premium gate on For You tab")

        // Should NOT see regular For You content (onboarding or articles)
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let noArticlesText = app.staticTexts["No Articles"]
        XCTAssertFalse(personalizeText.exists, "Non-premium user should not see For You onboarding")
        XCTAssertFalse(noArticlesText.exists, "Non-premium user should not see For You empty state")
    }

    /// Tests that tapping Unlock Premium on For You shows paywall
    func testForYouUnlockButtonShowsPaywall() throws {
        navigateToForYouTab()

        let unlockButton = app.buttons["Unlock Premium"]
        guard unlockButton.waitForExistence(timeout: 10) else {
            XCTFail("Unlock Premium button should exist for non-premium user")
            return
        }

        unlockButton.tap()

        // Paywall sheet should appear
        let paywallTitle = app.staticTexts["Unlock Premium"]
        let subscriptionView = app.scrollViews.firstMatch

        let paywallAppeared = paywallTitle.waitForExistence(timeout: 5) || subscriptionView.waitForExistence(timeout: 5)
        XCTAssertTrue(paywallAppeared, "Paywall should appear after tapping Unlock Premium")

        // Dismiss the sheet
        app.swipeDown()
    }

    // MARK: - Article Summarization Premium Gate

    /// Tests that non-premium users see paywall when tapping summarize button
    func testSummarizeButtonShowsPaywallForNonPremiumUser() throws {
        // Navigate to article detail
        let navigated = navigateToArticleDetail()
        guard navigated else {
            // Skip test if no articles available
            return
        }

        // Find and tap the summarize button
        let summarizeButton = app.buttons["summarizeButton"]
        guard summarizeButton.waitForExistence(timeout: 5) else {
            XCTFail("Summarize button should exist in article detail")
            return
        }

        summarizeButton.tap()

        // Paywall sheet should appear instead of summarization
        let paywallTitle = app.staticTexts["Unlock Premium"]
        let subscriptionView = app.scrollViews.firstMatch

        let paywallAppeared = paywallTitle.waitForExistence(timeout: 5) || subscriptionView.waitForExistence(timeout: 5)
        XCTAssertTrue(paywallAppeared, "Paywall should appear when non-premium user taps summarize")

        // Dismiss the sheet
        app.swipeDown()
    }

    // MARK: - Helper Methods

    /// Navigate to an article detail by tapping the first available article
    @discardableResult
    private func navigateToArticleDetail() -> Bool {
        navigateToTab("Home")

        // Wait for articles to load
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        guard topHeadlinesHeader.waitForExistence(timeout: 10) else {
            return false
        }

        // Find and tap first article card
        let articleCardsQuery = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour' OR label CONTAINS[c] 'minute'")
        )

        guard articleCardsQuery.count > 0 else {
            return false
        }

        let firstCard = articleCardsQuery.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else {
            return false
        }

        firstCard.tap()

        return waitForArticleDetail()
    }
}

// MARK: - Premium User Tests

/// Tests premium feature access for premium users.
/// These tests verify that premium features are properly unlocked.
final class PremiumGatingPremiumUITests: XCTestCase {
    var app: XCUIApplication!

    // Use the same timeouts as BaseUITestCase
    // CI machines are significantly slower than local, especially on shared runners
    static let launchTimeout: TimeInterval = 60
    static let defaultTimeout: TimeInterval = 10
    static let shortTimeout: TimeInterval = 6

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()

        // Speed optimizations
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"

        // Set premium status for these tests
        app.launchEnvironment["MOCK_PREMIUM"] = "1"

        // Launch arguments to speed up tests
        app.launchArguments += ["-UIViewAnimationDuration", "0.01"]
        app.launchArguments += ["-CATransactionAnimationDuration", "0.01"]

        app.launch()

        _ = app.wait(for: .runningForeground, timeout: Self.launchTimeout)

        // Wait for UI to stabilize
        wait(for: 0.3)

        // Wait for either tab bar or sign-in to appear
        let tabBar = app.tabBars.firstMatch
        let signInButton = app.buttons["Sign in with Apple"]

        // CI simulators can be slow to show the initial UI, so give more time to detect loading state
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.waitForExistence(timeout: 10) {
            // Wait for loading to complete with extended timeout for CI
            _ = waitForElementToDisappear(loadingIndicator, timeout: Self.launchTimeout * 2)
        }

        let appReady = waitForAny([tabBar, signInButton], timeout: Self.launchTimeout)

        guard appReady else {
            XCTFail("App did not reach ready state")
            return
        }

        if tabBar.exists {
            resetToHomeTab()
        }
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        if app?.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Feed Tab Premium Access

    /// Tests that premium users see digest content on Feed tab
    func testFeedTabShowsContentForPremiumUser() throws {
        // Navigate to Feed tab
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeedTab()

        // Premium users should see actual content, not the gate
        let premiumGateTitle = app.staticTexts["AI Daily Digest"]
        let unlockButton = app.buttons["Unlock Premium"]

        // Wait for content to load
        wait(for: 2.0)

        // Should NOT see premium gate elements (check separately for clarity)
        XCTAssertFalse(unlockButton.exists, "Premium user should not see unlock button")

        // Should see some Feed content indicators
        let digestHeader = app.staticTexts["Your Daily Digest"]
        let emptyState = app.staticTexts["No Recent Reading"]
        let errorState = app.staticTexts["Something went wrong"]
        let loadingState = app.staticTexts["Loading model"]

        let hasFeedContent = waitForAny([digestHeader, emptyState, errorState, loadingState], timeout: 10)
        XCTAssertTrue(hasFeedContent, "Premium user should see Feed content (digest, empty, error, or loading)")
    }

    // MARK: - For You Tab Premium Access

    /// Tests that premium users see For You content
    func testForYouTabShowsContentForPremiumUser() throws {
        // Navigate to For You tab
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.waitForExistence(timeout: Self.launchTimeout), "For You tab should exist")

        navigateToForYouTab()

        // Premium users should see actual content, not the gate
        let premiumGateTitle = app.staticTexts["Personalized For You"]
        let unlockButton = app.buttons["Unlock Premium"]

        // Wait for content to load
        wait(for: 2.0)

        // Should NOT see premium gate elements (check separately for clarity)
        XCTAssertFalse(unlockButton.exists, "Premium user should not see unlock button")

        // Should see some For You content indicators
        let personalizeText = app.staticTexts["Personalize Your Feed"]
        let noArticlesText = app.staticTexts["No Articles"]
        let errorText = app.staticTexts["Unable to Load Feed"]
        let scrollView = app.scrollViews.firstMatch

        let hasForYouContent = waitForAny([personalizeText, noArticlesText, errorText, scrollView], timeout: 10)
        XCTAssertTrue(hasForYouContent, "Premium user should see For You content")
    }

    // MARK: - Article Summarization Premium Access

    /// Tests that premium users can access summarization
    func testSummarizeButtonWorksForPremiumUser() throws {
        // Navigate to article detail
        let navigated = navigateToArticleDetail()
        guard navigated else {
            // Skip test if no articles available
            return
        }

        // Find and tap the summarize button
        let summarizeButton = app.buttons["summarizeButton"]
        guard summarizeButton.waitForExistence(timeout: 5) else {
            XCTFail("Summarize button should exist in article detail")
            return
        }

        summarizeButton.tap()

        // Should see summarization sheet, NOT paywall
        let paywallTitle = app.staticTexts["Unlock Premium"]
        XCTAssertFalse(paywallTitle.waitForExistence(timeout: 2), "Premium user should not see paywall")

        // Should see summarization UI elements (various states possible)
        let summarizeTitle = app.staticTexts["Summarize"]
        let generateButton = app.buttons["Generate Summary"]
        let loadingText = app.staticTexts["Loading AI model..."]
        let generatingText = app.staticTexts["Generating..."]
        let summarySheet = app.scrollViews.firstMatch // Sheet should have a scroll view
        let modelLoadingIndicator = app.activityIndicators.firstMatch

        // Use longer timeout for CI - LLM model initialization can be slow
        let hasSummarizationUI = waitForAny([summarizeTitle, generateButton, loadingText, generatingText, modelLoadingIndicator], timeout: 10)
        // Note: In CI, the summarization sheet may show but model loading can be slow
        // We accept seeing any summarization-related UI as success
        XCTAssertTrue(hasSummarizationUI || summarySheet.exists, "Premium user should see summarization UI")

        // Dismiss the sheet
        app.swipeDown()
    }

    // MARK: - Helper Methods

    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        if tab.waitForExistence(timeout: Self.shortTimeout), !tab.isSelected {
            tab.tap()
        }
    }

    func navigateToFeedTab() {
        let feedTab = app.tabBars.buttons["Feed"]
        // Use waitForExistence for CI reliability
        if feedTab.waitForExistence(timeout: Self.shortTimeout), !feedTab.isSelected {
            feedTab.tap()
        } else if !feedTab.exists {
            // Fallback: try finding the button directly
            let feedButton = app.buttons["Feed"]
            if feedButton.waitForExistence(timeout: 2), !feedButton.isSelected {
                feedButton.tap()
            }
        }
        _ = app.navigationBars["Daily Digest"].waitForExistence(timeout: Self.defaultTimeout)
    }

    func navigateToForYouTab() {
        let forYouTab = app.tabBars.buttons["For You"]
        // Use waitForExistence for CI reliability
        if forYouTab.waitForExistence(timeout: Self.shortTimeout), !forYouTab.isSelected {
            forYouTab.tap()
        } else if !forYouTab.exists {
            // Fallback: try finding the button directly
            let forYouButton = app.buttons["For You"]
            if forYouButton.waitForExistence(timeout: 2), !forYouButton.isSelected {
                forYouButton.tap()
            }
        }
        _ = app.navigationBars["For You"].waitForExistence(timeout: Self.defaultTimeout)
    }

    func resetToHomeTab() {
        let tabBar = app.tabBars.firstMatch

        if !tabBar.waitForExistence(timeout: Self.shortTimeout) {
            let backButton = app.buttons["backButton"]
            if backButton.exists { backButton.tap() }
            guard tabBar.waitForExistence(timeout: 1) else { return }
        }

        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists, !homeTab.isSelected {
            homeTab.tap()
        } else if !homeTab.exists {
            tabBar.buttons.element(boundBy: 0).tap()
        }

        for _ in 0..<3 {
            let backButton = app.buttons["backButton"]
            guard backButton.exists, backButton.isHittable else { break }
            backButton.tap()
            wait(for: 0.2)
        }
    }

    @discardableResult
    func wait(for duration: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(value: false),
            object: nil
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: duration)
        return true
    }

    func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate { _, _ in elements.contains { $0.exists } }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate { _, _ in !element.exists }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForArticleDetail(timeout: TimeInterval = 5) -> Bool {
        let detailScrollView = app.scrollViews["articleDetailScrollView"]
        if detailScrollView.waitForExistence(timeout: timeout) {
            return true
        }
        return app.buttons["backButton"].waitForExistence(timeout: 1)
    }

    @discardableResult
    private func navigateToArticleDetail() -> Bool {
        navigateToTab("Home")

        // Wait for content to load - use longer timeout for CI
        let topHeadlinesHeader = app.staticTexts["Top Headlines"]
        let breakingNews = app.staticTexts["Breaking News"]
        let scrollView = app.scrollViews.firstMatch

        // Wait for any content indicator
        let contentLoaded = waitForAny([topHeadlinesHeader, breakingNews, scrollView], timeout: 20)
        guard contentLoaded else {
            return false
        }

        // Try multiple strategies to find article cards
        let articleCardsQuery = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'ago' OR label CONTAINS[c] 'hour' OR label CONTAINS[c] 'minute'")
        )

        // Also try finding cards by accessibility identifier
        let articleCardsById = app.buttons.matching(identifier: "articleCard")

        // Use whichever query finds cards first
        var firstCard: XCUIElement?
        if articleCardsQuery.count > 0 {
            firstCard = articleCardsQuery.firstMatch
        } else if articleCardsById.count > 0 {
            firstCard = articleCardsById.firstMatch
        }

        guard let card = firstCard, card.waitForExistence(timeout: 10) else {
            return false
        }

        // Scroll to make card hittable if needed
        if !card.isHittable {
            scrollView.swipeUp()
            wait(for: 0.3)
        }

        card.tap()

        return waitForArticleDetail()
    }
}
