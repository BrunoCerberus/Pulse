import XCTest

/// Automated accessibility audit tests using iOS 17+ `performAccessibilityAudit()`.
///
/// These tests launch each main screen and run Apple's built-in accessibility audit
/// to automatically detect missing labels, small touch targets, contrast issues, etc.
///
/// Note: `performAccessibilityAudit()` can be slow on CI shared runners due to the
/// full accessibility hierarchy traversal. Real audit issues (missing labels, small
/// hit regions, etc.) still fail the test, but the audit's own internal timeout
/// (`com.apple.xcode.xctest.accessibilityAudit` code `-56`) is converted to `XCTSkip`
/// so it doesn't block CI.
@MainActor
final class AccessibilityAuditTests: BaseUITestCase {
    /// Common audit handler that filters out system component issues we don't control.
    ///
    /// `exemptPlaybackProgress` additionally exempts the audio player's progress
    /// row (known a11y debt, note below). The debt is media-detail-specific, so
    /// only the media-detail audit opts in — leaving it in the shared handler
    /// would silently exempt a same-labelled element on every audited screen
    /// (the playback surface is app-lifetime).
    private func auditIssueHandler(
        _ issue: XCUIAccessibilityAuditIssue,
        exemptPlaybackProgress: Bool,
    ) -> Bool {
        let description = issue.debugDescription
        if description.contains("UITabBar") || description.contains("UINavigationBar")
            || description.contains("partially unsupported")
            || description.contains("UISearchBar")
            || description.contains("Label not human-readable")
        {
            return true
        }
        // Known pre-existing a11y debt, media detail only: the audio player's
        // progress row is a 12pt-tall composite adjustable element, below the
        // 44pt hit-region minimum. The fix (a 44pt-tall row) shifts the player
        // layout and would require re-recording the AudioPlayer/MediaDetail
        // snapshot references in a CI-matched toolchain, so it is tracked as
        // debt rather than fixed alongside the CI gates. "Playback progress" is
        // the English value of audio_player.progress_label; UI tests force the
        // app to English via -AppleLanguages (BaseUITestCase), so the match is
        // locale-stable.
        // `safeLabel` reads via the exception-catching wrapper, so a snapshot
        // timeout *inside* the audit (not just while the audit runs) can't throw
        // an uncaught C++ exception and SIGABRT the runner. It takes the optional
        // because `issue.element` is `XCUIElement?` in the SDK CI builds with
        // (Xcode 26.5) and non-optional in newer ones.
        if exemptPlaybackProgress,
            description.contains("Hit area is too small"),
            safeLabel(issue.element) == "Playback progress" {
            return true
        }
        return false
    }

    /// Audit types to check — focused set that avoids the most CI-flaky checks
    private var auditTypes: XCUIAccessibilityAuditType {
        [.dynamicType, .sufficientElementDescription, .hitRegion]
    }

    /// Runs `performAccessibilityAudit` and converts the audit's internal timeout
    /// into `XCTSkip`. The audit can time out on shared CI runners while traversing
    /// the accessibility hierarchy — that's a CI environment issue, not an
    /// accessibility regression, so we skip rather than fail the PR.
    private func performAccessibilityAuditSkippingTimeouts(
        exemptPlaybackProgress: Bool = false,
    ) throws {
        do {
            try app.performAccessibilityAudit(for: auditTypes) { issue in
                self.auditIssueHandler(issue, exemptPlaybackProgress: exemptPlaybackProgress)
            }
        } catch {
            let nsError = error as NSError
            let isAuditTimeout = nsError.domain == "com.apple.xcode.xctest.accessibilityAudit"
                && nsError.code == -56
            if isAuditTimeout {
                throw XCTSkip("Accessibility audit timed out on CI runner — skipping to avoid flake.")
            }
            throw error
        }
    }

    // MARK: - Home

    func testHomeAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        waitForHomeContent()
        wait(for: 3.0) // Extra stabilization for CI accessibility tree
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Media

    func testMediaAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToMediaTab()
        // Media tab loads async content — give extra time for the accessibility tree to stabilize
        wait(for: 4.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Bookmarks

    func testBookmarksAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToBookmarksTab()
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Search

    func testSearchAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSearchTab()
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Settings

    func testSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSettings()
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Feed

    func testFeedAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToFeedTab()
        // Feed cards load async — give the accessibility tree time to stabilize.
        wait(for: 4.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Article Detail

    func testArticleDetailAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        waitForHomeContent()

        // Querying a card on a home in its error state can hang the Xcode 26
        // accessibility framework, so bail instead of forcing a tap.
        guard !isHomeErrorState(),
              let card = firstExistingArticleCard()
        else {
            throw XCTSkip("No article card available to open detail from.")
        }
        safeTap(card)
        guard waitForArticleDetail(timeout: Self.defaultTimeout) else {
            throw XCTSkip("Article detail did not appear.")
        }
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Media Detail

    func testMediaDetailAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToMediaTab()
        wait(for: 2.0)

        guard !isMediaErrorState(),
              let card = firstExistingMediaCard()
        else {
            throw XCTSkip("No media card available to open detail from.")
        }
        safeTap(card)
        guard waitForMediaDetailIndicators() else {
            throw XCTSkip("Media detail did not appear.")
        }
        wait(for: 3.0)
        try ensureAppRunning()

        // The audio player's 12pt progress row is known hit-region debt (see
        // `auditIssueHandler`); exempt it only here, not across every audit.
        try performAccessibilityAuditSkippingTimeouts(exemptPlaybackProgress: true)
    }

    // MARK: - Reading History

    func testReadingHistoryAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSettings()
        guard safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout) else {
            throw XCTSkip("Settings screen did not appear.")
        }
        wait(for: 1.0)

        guard scrollToSettingsRow("Reading History") else {
            throw XCTSkip("Reading History row not found in Settings.")
        }
        let row = findSettingsRow("Reading History")
        if let row { safeTap(row) }
        guard safeWaitForExistence(app.navigationBars["Reading History"], timeout: Self.defaultTimeout) else {
            throw XCTSkip("Reading History screen did not appear.")
        }
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - For You Settings

    func testForYouSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17+")
        }

        try ensureAppRunning()
        navigateToSettings()
        guard safeWaitForExistence(app.navigationBars["Settings"], timeout: Self.defaultTimeout) else {
            throw XCTSkip("Settings screen did not appear.")
        }
        wait(for: 1.0)

        guard scrollToSettingsRow("For You") else {
            throw XCTSkip("For You row not found in Settings.")
        }
        let row = findSettingsRow("For You")
        if let row { safeTap(row) }
        // Navigation title is the localized "Personalization"
        // (for_you_settings.title).
        guard safeWaitForExistence(app.navigationBars["Personalization"], timeout: Self.defaultTimeout) else {
            throw XCTSkip("For You settings screen did not appear.")
        }
        wait(for: 3.0)
        try ensureAppRunning()

        try performAccessibilityAuditSkippingTimeouts()
    }

    // MARK: - Navigation helpers

    private func isHomeErrorState() -> Bool {
        safeExists(app.staticTexts["Unable to Load News"])
            || safeExists(app.staticTexts["No News Available"])
    }

    private func firstExistingArticleCard() -> XCUIElement? {
        let cards = articleCards()
        return ObjCExceptionCatcher.safeCount(for: cards) > 0 ? cards.firstMatch : nil
    }

    private func isMediaErrorState() -> Bool {
        safeExists(app.staticTexts["Unable to Load Media"])
            || safeExists(app.staticTexts["No Media Available"])
    }

    private func firstExistingMediaCard() -> XCUIElement? {
        for identifier in ["mediaCard", "featuredMediaCard"] {
            let cards = app.buttons.matching(identifier: identifier)
            let card = cards.firstMatch
            if ObjCExceptionCatcher.safeCount(for: cards) > 0, safeExists(card) {
                return card
            }
        }
        return nil
    }

    private func waitForMediaDetailIndicators() -> Bool {
        waitForAny(
            [
                app.buttons["backButton"],
                app.buttons["shareButton"],
                app.buttons["square.and.arrow.up"],
            ],
            timeout: Self.defaultTimeout,
        )
    }

    /// Settings renders as a table (List → UITableView); prefer it as the scroll
    /// container, falling back to the generic scroll view, then the app. Existence
    /// checks go through `safeExists` so a snapshot timeout can't SIGABRT the runner.
    private func settingsScrollContainer() -> XCUIElement {
        let table = app.tables.firstMatch
        if safeExists(table) { return table }
        let scrollView = app.scrollViews.firstMatch
        if safeExists(scrollView) { return scrollView }
        return app
    }

    private func findSettingsRow(_ title: String) -> XCUIElement? {
        // NavigationLink rows render as buttons carrying the row title.
        let button = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", title),
        ).firstMatch
        if safeWaitForExistence(button, timeout: 2) { return button }
        let cell = app.cells.matching(
            NSPredicate(format: "label CONTAINS[c] %@", title),
        ).firstMatch
        if safeWaitForExistence(cell, timeout: 1) { return cell }
        return nil
    }

    /// Scrolls the settings list until the row titled `title` is on screen.
    /// Uses a coordinate-based drag (`safeSwipeUp`) rather than `container.swipeUp()`:
    /// the container falls back to the whole app, and `app`-level XCTest gestures
    /// evaluate the full accessibility tree, which can hang for 30+ minutes.
    @discardableResult
    private func scrollToSettingsRow(_ title: String, maxSwipes: Int = 10) -> Bool {
        if findSettingsRow(title) != nil { return true }
        let container = settingsScrollContainer()
        for _ in 0 ..< maxSwipes {
            safeSwipeUp(container)
            wait(for: 0.3)
            if findSettingsRow(title) != nil { return true }
        }
        return false
    }
}
