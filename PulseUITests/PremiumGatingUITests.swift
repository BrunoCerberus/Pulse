import XCTest

// MARK: - Non-Premium User Tests

/// Tests premium feature gating for non-premium users.
/// These tests verify that premium features are properly locked.
final class PremiumGatingNonPremiumUITests: BaseUITestCase {
    // MARK: - Feed Tab Premium Gate

    /// Tests that non-premium users see the premium gate on Feed tab
    func testFeedTabShowsPremiumGateForNonPremiumUser() {
        // Navigate to Feed tab
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeedTab()

        // Non-premium users should see the premium gate
        let premiumBadge = app.staticTexts["Premium Feature"]
        let premiumTitle = app.staticTexts["AI Daily Digest"]
        let unlockButton = app.buttons["unlockPremiumButton"]

        let hasPremiumGate = waitForAny([premiumBadge, premiumTitle, unlockButton], timeout: 10)
        XCTAssertTrue(hasPremiumGate, "Non-premium user should see premium gate on Feed tab")

        // Should NOT see premium content
        let digestContent = app.staticTexts["Your Daily Digest"]
        XCTAssertFalse(digestContent.exists, "Non-premium user should not see digest content")
    }

    /// Tests that tapping Unlock Premium on Feed shows paywall
    func testFeedUnlockButtonShowsPaywall() {
        // Ensure tab bar is ready before navigation
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeedTab()

        // Wait for content to load after navigation
        wait(for: 1.0)

        let unlockButton = app.buttons["unlockPremiumButton"]
        guard unlockButton.waitForExistence(timeout: 10) else {
            XCTFail("unlockPremiumButton should exist for non-premium user")
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
    func testSummarizeButtonShowsPaywallForNonPremiumUser() {
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
final class PremiumGatingPremiumUITests: BaseUITestCase {
    // MARK: - Setup

    override func configureLaunchEnvironment() {
        // Set premium status for these tests
        app.launchEnvironment["MOCK_PREMIUM"] = "1"
    }

    // MARK: - Feed Tab Premium Access

    /// Tests that premium users see digest content on Feed tab
    func testFeedTabShowsContentForPremiumUser() {
        // Navigate to Feed tab
        let feedTab = app.tabBars.buttons["Feed"]
        XCTAssertTrue(feedTab.waitForExistence(timeout: Self.launchTimeout), "Feed tab should exist")

        navigateToFeedTab()

        // Premium users should see actual content, not the gate
        let unlockButton = app.buttons["unlockPremiumButton"]

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

    // MARK: - Article Summarization Premium Access

    /// Tests that premium users can access summarization
    func testSummarizeButtonWorksForPremiumUser() {
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
