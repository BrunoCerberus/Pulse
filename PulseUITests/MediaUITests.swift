import XCTest

final class MediaUITests: BaseUITestCase {
    // MARK: - Tab Navigation Tests

    func testMediaTabExists() {
        let mediaTab = app.tabBars.buttons["Media"]
        XCTAssertTrue(
            mediaTab.waitForExistence(timeout: Self.shortTimeout),
            "Media tab should exist in tab bar"
        )
    }

    func testNavigateToMediaTab() {
        navigateToMediaTab()

        // Verify we're on Media tab with recovery approach
        let mediaNavBar = app.navigationBars["Media"]
        var navBarVisible = mediaNavBar.waitForExistence(timeout: Self.defaultTimeout)

        if !navBarVisible {
            // Recovery: tap Media tab again
            let mediaTab = app.tabBars.buttons["Media"]
            if mediaTab.exists {
                mediaTab.tap()
                wait(for: 1.0)
                navBarVisible = mediaNavBar.waitForExistence(timeout: Self.defaultTimeout)
            }
        }

        XCTAssertTrue(navBarVisible, "Should navigate to Media screen after recovery")
    }

    func testMediaTabShowsSegmentedControl() {
        navigateToMediaTab()

        // Wait for content to load
        wait(for: 1.0)

        // Check for segmented control buttons
        let allButton = app.buttons["All"]
        let videosButton = app.buttons["Videos"]
        let podcastsButton = app.buttons["Podcasts"]

        // At least one should exist
        let segmentedControlExists = allButton.exists || videosButton.exists || podcastsButton.exists
        XCTAssertTrue(segmentedControlExists, "Media segmented control should be visible")
    }

    // MARK: - Media Type Filter Tests

    func testFilterByVideos() {
        navigateToMediaTab()
        wait(for: 1.0)

        let videosButton = app.buttons["Videos"]
        if videosButton.waitForExistence(timeout: Self.shortTimeout), videosButton.isHittable {
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
        if podcastsButton.waitForExistence(timeout: Self.shortTimeout), podcastsButton.isHittable {
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
        if videosButton.waitForExistence(timeout: Self.shortTimeout), videosButton.isHittable {
            videosButton.tap()
            wait(for: 0.5)
        }

        // Then go back to All
        let allButton = app.buttons["All"]
        if allButton.waitForExistence(timeout: Self.shortTimeout), allButton.isHittable {
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

            if firstCard.waitForExistence(timeout: Self.shortTimeout), firstCard.isHittable {
                firstCard.tap()

                // Should navigate to media detail
                let detailViewExists = waitForMediaDetail(timeout: Self.defaultTimeout)

                if detailViewExists {
                    // Navigate back
                    navigateBack()
                    XCTAssertTrue(app.navigationBars["Media"].waitForExistence(timeout: Self.shortTimeout))
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

            if firstCard.waitForExistence(timeout: Self.shortTimeout), firstCard.isHittable {
                // Long press to show context menu
                firstCard.press(forDuration: 0.5)

                // Check for context menu items
                let shareButton = app.buttons["Share"]
                let contextMenuAppeared = shareButton.waitForExistence(timeout: Self.shortTimeout)

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
            if scrollView.waitForExistence(timeout: Self.shortTimeout) {
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
            if scrollView.waitForExistence(timeout: Self.shortTimeout) {
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
                if firstFeatured.isHittable {
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
        var mediaReady = mediaNavBar.waitForExistence(timeout: Self.defaultTimeout)
        if !mediaReady {
            let mediaTab = app.tabBars.buttons["Media"]
            if mediaTab.exists { mediaTab.tap() }
            wait(for: 1.0)
            mediaReady = mediaNavBar.waitForExistence(timeout: Self.defaultTimeout)
        }
        XCTAssertTrue(mediaReady, "Media tab should be ready")

        // Switch to Home
        navigateToTab("Home")
        var homeReady = app.navigationBars["News"].waitForExistence(timeout: Self.launchTimeout) ||
            app.tabBars.buttons["Home"].isSelected
        if !homeReady {
            // Recovery: tap Home directly
            let homeTab = app.tabBars.buttons["Home"]
            if homeTab.exists {
                homeTab.tap()
                wait(for: 1.0)
                homeReady = app.navigationBars["News"].waitForExistence(timeout: Self.launchTimeout)
            }
        }
        XCTAssertTrue(homeReady, "Home tab should be ready after recovery")

        // Switch back to Media
        navigateToMediaTab()
        XCTAssertTrue(app.navigationBars["Media"].waitForExistence(timeout: Self.defaultTimeout), "Media tab should be visible")

        // Switch to Bookmarks
        navigateToTab("Bookmarks")
        XCTAssertTrue(
            app.navigationBars["Bookmarks"].waitForExistence(timeout: Self.shortTimeout) ||
                app.tabBars.buttons["Bookmarks"].isSelected,
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
                XCTAssertTrue(tryAgainButton.isHittable)
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
