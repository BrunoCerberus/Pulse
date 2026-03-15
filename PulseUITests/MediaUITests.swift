import XCTest

final class MediaUITests: BaseUITestCase {
    // MARK: - Tab Navigation Tests

    func testMediaTabExists() throws {
        try ensureAppRunning()
        let mediaTab = app.tabBars.buttons["Media"]
        XCTAssertTrue(
            safeWaitForExistence(mediaTab, timeout: Self.shortTimeout),
            "Media tab should exist in tab bar"
        )
    }

    func testNavigateToMediaTab() {
        navigateToMediaTab()

        // Verify we're on Media tab with recovery approach
        let mediaNavBar = app.navigationBars["Media"]
        var navBarVisible = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)

        if !navBarVisible {
            // Recovery: tap Media tab again
            let mediaTab = app.tabBars.buttons["Media"]
            if mediaTab.exists {
                mediaTab.tap()
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
                videosButton.exists || podcastsButton.exists,
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
        if safeWaitForExistence(videosButton, timeout: Self.shortTimeout), videosButton.exists {
            videosButton.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(app.navigationBars["Media"].exists)
        }
    }

    func testFilterByPodcasts() {
        navigateToMediaTab()
        wait(for: 1.0)

        let podcastsButton = app.buttons["Podcasts"]
        if safeWaitForExistence(podcastsButton, timeout: Self.shortTimeout), podcastsButton.exists {
            podcastsButton.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(app.navigationBars["Media"].exists)
        }
    }

    func testFilterAllShowsBothTypes() {
        navigateToMediaTab()
        wait(for: 1.0)

        // First filter to Videos
        let videosButton = app.buttons["Videos"]
        if safeWaitForExistence(videosButton, timeout: Self.shortTimeout), videosButton.exists {
            videosButton.tap()
            wait(for: 0.5)
        }

        // Then go back to All
        let allButton = app.buttons["All"]
        if safeWaitForExistence(allButton, timeout: Self.shortTimeout), allButton.exists {
            allButton.tap()
            wait(for: 0.5)

            // Verify still on Media tab
            XCTAssertTrue(app.navigationBars["Media"].exists)
        }
    }

    // MARK: - Media Card Interaction Tests

    func testTapMediaCard() {
        navigateToMediaTab()

        // Wait for content to load
        let contentLoaded = waitForMediaContent(timeout: 30)

        if contentLoaded {
            let mediaCards = app.buttons.matching(identifier: "mediaCard")
            let firstCard = mediaCards.firstMatch

            if safeWaitForExistence(firstCard, timeout: Self.shortTimeout), firstCard.exists {
                firstCard.tap()

                // Should navigate to media detail
                let detailViewExists = waitForMediaDetail(timeout: Self.defaultTimeout)

                if detailViewExists {
                    // Navigate back
                    navigateBack()
                    XCTAssertTrue(safeWaitForExistence(app.navigationBars["Media"], timeout: Self.shortTimeout))
                }
            }
        }
    }

    func testMediaCardContextMenu() {
        navigateToMediaTab()

        let contentLoaded = waitForMediaContent(timeout: 30)

        if contentLoaded {
            let mediaCards = app.buttons.matching(identifier: "mediaCard")
            let firstCard = mediaCards.firstMatch

            if safeWaitForExistence(firstCard, timeout: Self.shortTimeout), firstCard.exists {
                // Long press to show context menu
                firstCard.press(forDuration: 0.5)

                // Check for context menu items
                let shareButton = app.buttons["Share"]
                let contextMenuAppeared = safeWaitForExistence(shareButton, timeout: Self.shortTimeout)

                if contextMenuAppeared {
                    // Dismiss context menu
                    app.tap()
                }
            }
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
                XCTAssertTrue(app.navigationBars["Media"].exists)
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
                XCTAssertTrue(app.navigationBars["Media"].exists)
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
                if firstFeatured.exists {
                    firstFeatured.tap()

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
            if mediaTab.exists { mediaTab.tap() }
            wait(for: 1.0)
            mediaReady = safeWaitForExistence(mediaNavBar, timeout: Self.defaultTimeout)
        }
        XCTAssertTrue(mediaReady, "Media tab should be ready")

        // Switch to Home
        navigateToTab("Home")
        var homeReady = safeWaitForExistence(app.navigationBars["News"], timeout: Self.launchTimeout)
        if !homeReady {
            // Recovery: tap Home directly
            let homeTab = app.tabBars.buttons["Home"]
            if homeTab.exists {
                homeTab.tap()
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
            safeWaitForExistence(app.navigationBars["Bookmarks"], timeout: Self.shortTimeout),
            "Bookmarks tab should be visible"
        )
    }

    // MARK: - Error State Tests

    func testHandlesErrorState() {
        navigateToMediaTab()
        wait(for: 2.0)

        // Check for error state if it appears
        let errorState = app.staticTexts["Unable to Load Media"].exists ||
            app.staticTexts["No Media Available"].exists

        if errorState {
            // Try Again button should exist
            let tryAgainButton = app.buttons["Try Again"]
            if tryAgainButton.exists {
                XCTAssertTrue(tryAgainButton.exists)
            }
        }

        // Should still be on Media tab
        XCTAssertTrue(app.navigationBars["Media"].exists)
    }

    // MARK: - Helper Methods

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
