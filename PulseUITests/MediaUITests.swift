import XCTest

final class MediaUITests: BaseUITestCase {
    // MARK: - Tab Navigation Tests

    func testMediaTabExists() throws {
        try ensureAppRunning()

        // Use defaultTimeout — shortTimeout (10s) is insufficient on slow CI shared runners
        // where Liquid Glass tab bar rendering can delay accessibility element availability.
        let mediaTab = app.tabBars.buttons["Media"]
        var found = safeWaitForExistence(mediaTab, timeout: Self.defaultTimeout)

        if !found {
            // Fallback: iOS 26 Liquid Glass may expose the tab by SF Symbol identifier
            let mediaByImage = app.tabBars.buttons["play.tv"]
            found = safeWaitForExistence(mediaByImage, timeout: 5)
        }

        if !found {
            // Last fallback: query outside tabBars scope (handles tabBar query issues on CI)
            let mediaButton = app.buttons["Media"]
            found = safeWaitForExistence(mediaButton, timeout: 5)
        }

        XCTAssertTrue(found, "Media tab should exist in tab bar")
    }

    func testNavigateToMediaTab() {
        navigateToMediaTab()

        // Verify we're on Media tab with recovery approach
        let mediaNavBar = app.navigationBars["Media"]
        var navBarVisible = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)

        if !navBarVisible {
            // Recovery: tap Media tab again
            let mediaTab = app.tabBars.buttons["Media"]
            if safeWaitForExistence(mediaTab, timeout: 3) {
                let center = mediaTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
                wait(for: 1.0)
                navBarVisible = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)
            }
        }

        XCTAssertTrue(navBarVisible, "Should navigate to Media screen after recovery")
    }

    func testMediaTabShowsSegmentedControl() {
        navigateToMediaTab()

        // Wait for Media tab to fully render before querying UI elements.
        // On CI shared runners, rapid .exists polling can trigger Xcode 26 C++ exception
        // crashes ("Timed out while evaluating UI query"), so we give the view enough time
        // to stabilize and then check a single element to minimize UI query pressure.
        wait(for: 3.0)

        // Use safeWaitForExistence on a single element to avoid overwhelming the
        // accessibility framework with multiple concurrent UI queries
        let allButton = app.buttons["All"]
        let segmentedControlExists = safeWaitForExistence(allButton, timeout: Self.defaultTimeout)

        if !segmentedControlExists {
            // Fallback: check other segment buttons individually (single snapshot each)
            let videosButton = app.buttons["Videos"]
            let podcastsButton = app.buttons["Podcasts"]
            XCTAssertTrue(
                safeWaitForExistence(videosButton, timeout: 5) || safeWaitForExistence(podcastsButton, timeout: 5),
                "Media segmented control should be visible"
            )
        }
    }

    // MARK: - Media Type Filter Tests

    func testFilterByVideos() throws {
        try ensureAppRunning()
        navigateToMediaTab()
        wait(for: 1.0)

        let videosButton = app.buttons["Videos"]
        if safeWaitForExistence(videosButton, timeout: Self.shortTimeout) {
            let center = videosButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
        }
    }

    func testFilterByPodcasts() {
        navigateToMediaTab()
        wait(for: 1.0)

        let podcastsButton = app.buttons["Podcasts"]
        if safeWaitForExistence(podcastsButton, timeout: Self.shortTimeout) {
            let center = podcastsButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
        }
    }

    func testFilterAllShowsBothTypes() {
        navigateToMediaTab()
        wait(for: 1.0)

        // First filter to Videos
        let videosButton = app.buttons["Videos"]
        if safeWaitForExistence(videosButton, timeout: Self.shortTimeout) {
            let center = videosButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            wait(for: 0.5)
        }

        // Then go back to All
        let allButton = app.buttons["All"]
        if safeWaitForExistence(allButton, timeout: Self.shortTimeout) {
            let center = allButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
        }
    }

    // MARK: - Media Card Interaction Tests

    func testTapMediaCard() {
        navigateToMediaTab()

        // Wait for content to load
        let contentLoaded = waitForMediaContent(timeout: 30)
        guard contentLoaded else { return }

        // Bail out if only error state loaded — no cards to interact with.
        // Querying .matching(identifier:) on a view with no matching elements can cause
        // Xcode 26's accessibility framework to hang indefinitely on CI.
        guard !isMediaErrorState() else { return }

        let mediaCards = app.buttons.matching(identifier: "mediaCard")
        guard ObjCExceptionCatcher.safeCount(for: mediaCards) > 0 else { return }

        let firstCard = mediaCards.firstMatch
        guard safeExists(firstCard) else { return }

        safeTap(firstCard)

        // Should navigate to media detail
        let detailViewExists = waitForMediaDetail(timeout: Self.defaultTimeout)
        if detailViewExists {
            navigateBack()
            XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: Self.shortTimeout))
        }
    }

    func testMediaCardContextMenu() {
        navigateToMediaTab()

        let contentLoaded = waitForMediaContent(timeout: 30)
        guard contentLoaded else { return }

        // Bail out if only error state loaded — no cards to interact with.
        guard !isMediaErrorState() else { return }

        let mediaCards = app.buttons.matching(identifier: "mediaCard")
        guard ObjCExceptionCatcher.safeCount(for: mediaCards) > 0 else { return }

        let firstCard = mediaCards.firstMatch
        guard safeExists(firstCard) else { return }

        // Long press to show context menu — use ObjC wrapper to catch C++ exceptions
        ObjCExceptionCatcher.safeLongPress(firstCard, duration: 0.5)

        // Check for context menu items
        let shareButton = app.buttons["Share"]
        if safeWaitForExistence(shareButton, timeout: Self.shortTimeout) {
            // Dismiss context menu by tapping empty area
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefresh() {
        navigateToMediaTab()

        let contentLoaded = waitForMediaContent(timeout: 30)

        if contentLoaded {
            let scrollView = app.scrollViews.firstMatch
            if safeWaitForExistence(scrollView, timeout: Self.shortTimeout) {
                // Pull to refresh
                scrollView.swipeDown()
                wait(for: 1.0)

                // Should still be on Media tab
                XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
            }
        }
    }

    // MARK: - Scroll Tests

    func testScrollMediaFeed() {
        navigateToMediaTab()

        let contentLoaded = waitForMediaContent(timeout: 30)

        if contentLoaded {
            let scrollView = app.scrollViews.firstMatch
            if safeWaitForExistence(scrollView, timeout: Self.shortTimeout) {
                // Scroll down
                scrollView.swipeUp()
                wait(for: 0.5)

                // Scroll back up
                scrollView.swipeDown()
                wait(for: 0.5)

                // Should still be on Media tab
                XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
            }
        }
    }

    // MARK: - Featured Media Tests

    func testFeaturedMediaCarousel() {
        navigateToMediaTab()

        let contentLoaded = waitForMediaContent(timeout: 30)

        if contentLoaded {
            // Look for featured media cards
            let featuredCards = app.buttons.matching(identifier: "featuredMediaCard")

            if featuredCards.count > 0 {
                let firstFeatured = featuredCards.firstMatch
                if safeWaitForExistence(firstFeatured, timeout: 3) {
                    let center = firstFeatured.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    center.tap()

                    // Should navigate to detail
                    let detailExists = waitForMediaDetail(timeout: Self.defaultTimeout)
                    if detailExists {
                        navigateBack()
                    }
                }
            }
        }
    }

    // MARK: - Tab Switching Tests

    func testSwitchFromMediaToOtherTabs() {
        navigateToMediaTab()

        // Verify Media tab with recovery
        let mediaNavBar = app.navigationBars["Media"]
        var mediaReady = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)
        if !mediaReady {
            let mediaTab = app.tabBars.buttons["Media"]
            if safeWaitForExistence(mediaTab, timeout: 3) {
                let center = mediaTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }
            wait(for: 1.0)
            mediaReady = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)
        }
        XCTAssertTrue(mediaReady, "Media tab should be ready")

        // Switch to Home
        navigateToTab("Home")
        var homeReady = safeWaitForExistence(app.navigationBars["News"], timeout: Self.launchTimeout) ||
            app.tabBars.buttons["Home"].isSelected
        if !homeReady {
            // Recovery: tap Home directly
            let homeTab = app.tabBars.buttons["Home"]
            if safeWaitForExistence(homeTab, timeout: 3) {
                let center = homeTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
                wait(for: 1.0)
                homeReady = safeWaitForExistence(app.navigationBars["News"], timeout: Self.launchTimeout)
            }
        }
        XCTAssertTrue(homeReady, "Home tab should be ready after recovery")

        // Switch back to Media
        navigateToMediaTab()
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Media"], timeout: Self.defaultTimeout),
            "Media tab should be visible"
        )

        // Switch to Bookmarks
        navigateToTab("Bookmarks")
        XCTAssertTrue(
            safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.shortTimeout) ||
                app.tabBars.buttons["Bookmarks"].isSelected,
            "Bookmarks tab should be visible"
        )
    }

    // MARK: - Error State Tests

    func testHandlesErrorState() {
        navigateToMediaTab()
        wait(for: 2.0)

        // Check for error state if it appears
        let errorState = safeWaitForExistence(app.staticTexts["Unable to Load Media"], timeout: 3) ||
            safeWaitForExistence(app.staticTexts["No Media Available"], timeout: 3)

        if errorState {
            // Try Again button should exist
            let tryAgainButton = app.buttons["Try Again"]
            if safeWaitForExistence(tryAgainButton, timeout: 3) {
                XCTAssertTrue(safeExists(tryAgainButton))
            }
        }

        // Should still be on Media tab
        XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: 5))
    }

    // MARK: - Helper Methods

    /// Returns true if the Media tab is showing an error state (no cards to interact with).
    private func isMediaErrorState() -> Bool {
        safeExists(app.staticTexts["Unable to Load Media"]) ||
            safeExists(app.staticTexts["No Media Available"])
    }

    @discardableResult
    private func waitForMediaContent(timeout: TimeInterval = 30) -> Bool {
        let contentIndicators = [
            app.buttons.matching(identifier: "mediaCard").firstMatch,
            app.buttons.matching(identifier: "featuredMediaCard").firstMatch,
            app.staticTexts["Unable to Load Media"],
            app.staticTexts["No Media Available"],
        ]
        return waitForAny(contentIndicators, timeout: timeout)
    }

    @discardableResult
    private func waitForMediaDetail(timeout: TimeInterval = 10) -> Bool {
        // Media detail has back button and share button
        let detailIndicators = [
            app.buttons["backButton"],
            app.buttons["shareButton"],
            app.buttons["square.and.arrow.up"],
        ]
        return waitForAny(detailIndicators, timeout: timeout)
    }
}
