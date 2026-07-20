import Foundation
@testable import Pulse
import Testing

@Suite("AnalyticsEvent Tests")
struct AnalyticsEventTests {
    @Test("All event names are snake_case")
    func eventNamesAreSnakeCase() {
        let events: [AnalyticsEvent] = [
            .screenView(screen: .home),
            .articleOpened(source: .home),
            .articleBookmarked,
            .articleUnbookmarked,
            .articleShared,
            .searchPerformed(queryLength: 5, resultCount: 10),
            .categorySelected(category: "technology"),
            .mediaPlayed(type: "video"),
            .digestGenerated(success: true),
            .articleSummarized(success: true),
            .paywallShown(feature: "feed"),
            .purchaseStarted(productId: "com.test"),
            .purchaseCompleted(productId: "com.test"),
            .purchaseFailed(productId: "com.test", error: "fail"),
            .signIn(provider: "google", success: true),
            .signOut,
        ]

        for event in events {
            let name = event.name
            #expect(!name.isEmpty, "Event name should not be empty")
            #expect(!name.contains(" "), "Event name '\(name)' should not contain spaces")
            #expect(name == name.lowercased(), "Event name '\(name)' should be lowercase")
        }
    }

    @Test("screenView has screen_name parameter")
    func screenViewParameters() {
        let event = AnalyticsEvent.screenView(screen: .home)
        #expect(event.name == "screen_view")
        let params = event.parameters
        #expect(params?["screen_name"] as? String == "home")
    }

    @Test("articleOpened has source parameter")
    func articleOpenedParameters() {
        let event = AnalyticsEvent.articleOpened(source: .search)
        #expect(event.name == "article_opened")
        #expect(event.parameters?["source"] as? String == "search")
    }

    @Test("Events without parameters return nil")
    func nilParameters() {
        #expect(AnalyticsEvent.articleBookmarked.parameters == nil)
        #expect(AnalyticsEvent.articleUnbookmarked.parameters == nil)
        #expect(AnalyticsEvent.articleShared.parameters == nil)
        #expect(AnalyticsEvent.signOut.parameters == nil)
    }

    @Test("briefing events carry their counters as parameters")
    func briefingEventParameters() {
        #expect(AnalyticsEvent.briefingStarted(itemCount: 11).parameters?["item_count"] as? Int == 11)
        #expect(AnalyticsEvent.briefingStopped(itemsPlayed: 4).parameters?["items_played"] as? Int == 4)
        #expect(AnalyticsEvent.briefingCompleted.parameters == nil)
        #expect(AnalyticsEvent.briefingItemSkipped.parameters == nil)
    }

    @Test("searchPerformed has correct parameters")
    func searchPerformedParameters() {
        let event = AnalyticsEvent.searchPerformed(queryLength: 12, resultCount: 25)
        let params = event.parameters
        #expect(params?["query_length"] as? Int == 12)
        #expect(params?["result_count"] as? Int == 25)
    }

    @Test("categorySelected has category parameter")
    func categorySelectedParameters() {
        let event = AnalyticsEvent.categorySelected(category: "sports")
        #expect(event.parameters?["category"] as? String == "sports")
    }

    @Test("mediaPlayed has media_type parameter")
    func mediaPlayedParameters() {
        let event = AnalyticsEvent.mediaPlayed(type: "podcast")
        #expect(event.parameters?["media_type"] as? String == "podcast")
    }

    @Test("digestGenerated has success parameter")
    func digestGeneratedParameters() {
        let successEvent = AnalyticsEvent.digestGenerated(success: true)
        #expect(successEvent.parameters?["success"] as? Bool == true)

        let failEvent = AnalyticsEvent.digestGenerated(success: false)
        #expect(failEvent.parameters?["success"] as? Bool == false)
    }

    @Test("purchaseFailed has productId and error parameters")
    func purchaseFailedParameters() {
        let event = AnalyticsEvent.purchaseFailed(productId: "com.app.sub", error: "Network error")
        let params = event.parameters
        #expect(params?["product_id"] as? String == "com.app.sub")
        #expect(params?["error"] as? String == "Network error")
    }

    @Test("signIn has provider and success parameters")
    func signInParameters() {
        let event = AnalyticsEvent.signIn(provider: "apple", success: false)
        let params = event.parameters
        #expect(params?["provider"] as? String == "apple")
        #expect(params?["success"] as? Bool == false)
    }

    @Test("AnalyticsScreen raw values")
    func screenRawValues() {
        #expect(AnalyticsScreen.home.rawValue == "home")
        #expect(AnalyticsScreen.articleDetail.rawValue == "article_detail")
        #expect(AnalyticsScreen.mediaDetail.rawValue == "media_detail")
    }
}

@Suite("LiveAnalyticsService Sanitizer Tests")
struct LiveAnalyticsServiceSanitizerTests {
    @Test("String sanitizer redacts email addresses")
    func sanitizeStringRedactsEmail() {
        let result = LiveAnalyticsService.sanitize("Failed to auth user@example.com")
        #expect(result == "Failed to auth [REDACTED_EMAIL]")
    }

    @Test("String sanitizer redacts URL query parameters")
    func sanitizeStringRedactsQueryParams() {
        let result = LiveAnalyticsService.sanitize("Request to https://api.example.com/x?token=abc123")
        #expect(result.contains("[REDACTED_PARAMS]"))
        #expect(!result.contains("abc123"))
    }

    @Test("Recursive sanitizer walks nested dictionaries")
    func sanitizeAnyRecursesIntoDicts() {
        let input: [String: Any] = [
            "outer": "outer ok",
            "nested": [
                "email": "user@example.com",
                "ok": "fine",
            ],
        ]
        guard let sanitized = LiveAnalyticsService.sanitize(any: input) as? [String: Any] else {
            Issue.record("Expected dictionary back from sanitize")
            return
        }
        guard let nested = sanitized["nested"] as? [String: Any] else {
            Issue.record("Expected nested dict")
            return
        }
        #expect(nested["email"] as? String == "[REDACTED_EMAIL]")
        #expect(nested["ok"] as? String == "fine")
        #expect(sanitized["outer"] as? String == "outer ok")
    }

    @Test("Recursive sanitizer walks arrays")
    func sanitizeAnyRecursesIntoArrays() {
        let input: [Any] = ["fine", "leak@example.com", ["nested@example.com"]]
        guard let sanitized = LiveAnalyticsService.sanitize(any: input) as? [Any] else {
            Issue.record("Expected array back from sanitize")
            return
        }
        #expect(sanitized[0] as? String == "fine")
        #expect(sanitized[1] as? String == "[REDACTED_EMAIL]")
        guard let inner = sanitized[2] as? [Any] else {
            Issue.record("Expected nested array")
            return
        }
        #expect(inner[0] as? String == "[REDACTED_EMAIL]")
    }

    @Test("Recursive sanitizer leaves non-string scalars untouched")
    func sanitizeAnyLeavesScalars() {
        #expect((LiveAnalyticsService.sanitize(any: 42) as? Int) == 42)
        #expect((LiveAnalyticsService.sanitize(any: true) as? Bool) == true)
    }

    @Test("Recursive sanitizer walks NSArray")
    func sanitizeAnyRecursesIntoNSArray() {
        let nsArray: NSArray = ["fine", "leak@example.com"]
        guard let sanitized = LiveAnalyticsService.sanitize(any: nsArray) as? [Any] else {
            Issue.record("Expected array from NSArray case")
            return
        }
        #expect(sanitized[1] as? String == "[REDACTED_EMAIL]")
    }

    @Test("Recursive sanitizer walks NSDictionary with string keys")
    func sanitizeAnyRecursesIntoNSDictionary() {
        let nsDict: NSDictionary = ["k": "leak@example.com", "k2": "fine"]
        guard let sanitized = LiveAnalyticsService.sanitize(any: nsDict) as? [String: Any] else {
            Issue.record("Expected dictionary from NSDictionary case")
            return
        }
        #expect(sanitized["k"] as? String == "[REDACTED_EMAIL]")
        #expect(sanitized["k2"] as? String == "fine")
    }

    @Test("buildSanitizedUserInfo enriches with domain + code + sanitizes message")
    func buildSanitizedUserInfoEnrichesAndSanitizes() {
        let error = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Failed to auth user@example.com"],
        )
        let result = LiveAnalyticsService.buildSanitizedUserInfo(
            error: error,
            userInfo: ["original": "value"],
        )
        #expect(result["domain"] as? String == "TestDomain")
        #expect(result["code"] as? Int == 42)
        if let desc = result["localizedDescription"] as? String {
            #expect(desc.contains("[REDACTED_EMAIL]"))
            #expect(!desc.contains("user@example.com"))
        } else {
            Issue.record("Expected sanitized localizedDescription string")
        }
        #expect(result["original"] as? String == "value")
    }

    @Test("Event-parameter sanitization redacts PII the same way logEvent now does")
    func eventParametersAreSanitizedLikeLogEvent() {
        // Mirrors `LiveAnalyticsService.logEvent`'s new step:
        // `event.parameters.map { $0.mapValues(Self.sanitize(any:)) }`.
        let event = AnalyticsEvent.cloudSyncFailed(
            error: "Sync failed for user@example.com via https://api.example.com/x?token=abc123",
        )
        let sanitized = (event.parameters ?? [:]).mapValues(LiveAnalyticsService.sanitize(any:))
        let errorValue = sanitized["error"] as? String ?? ""

        #expect(!errorValue.contains("user@example.com"))
        #expect(errorValue.contains("[REDACTED_EMAIL]"))
        #expect(!errorValue.contains("abc123"))
    }
}

@Suite("MockAnalyticsService Tests")
struct MockAnalyticsServiceTests {
    @Test("Records logged events")
    func recordsEvents() {
        let mock = MockAnalyticsService()
        mock.logEvent(.screenView(screen: .home))
        mock.logEvent(.articleBookmarked)

        #expect(mock.loggedEvents.count == 2)
        #expect(mock.loggedEvents[0].name == "screen_view")
        #expect(mock.loggedEvents[1].name == "article_bookmarked")
    }

    @Test("Records errors")
    func recordsErrors() {
        let mock = MockAnalyticsService()
        let error = NSError(domain: "test", code: 42)
        mock.recordError(error, userInfo: ["key": "value"])

        #expect(mock.recordedErrors.count == 1)
        #expect((mock.recordedErrors[0].error as NSError).code == 42)
        #expect(mock.recordedErrors[0].userInfo?["key"] as? String == "value")
    }

    @Test("Records user ID")
    func recordsUserID() {
        let mock = MockAnalyticsService()
        #expect(mock.currentUserID == nil)

        mock.setUserID("user123")
        #expect(mock.currentUserID == "user123")

        mock.setUserID(nil)
        #expect(mock.currentUserID == nil)
    }

    @Test("Reset clears all state")
    func resetClearsState() {
        let mock = MockAnalyticsService()
        mock.logEvent(.articleBookmarked)
        mock.recordError(NSError(domain: "test", code: 1), userInfo: nil)
        mock.setUserID("user")

        mock.reset()

        #expect(mock.loggedEvents.isEmpty)
        #expect(mock.recordedErrors.isEmpty)
        #expect(mock.currentUserID == nil)
    }
}
