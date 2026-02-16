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

    @Test("Records user properties")
    func recordsUserProperties() {
        let mock = MockAnalyticsService()
        mock.setUserProperty("premium", forName: "subscription_type")

        #expect(mock.userProperties["subscription_type"] as? String == "premium")
    }

    @Test("Records log messages")
    func recordsLogMessages() {
        let mock = MockAnalyticsService()
        mock.log("Test message")

        #expect(mock.loggedMessages.count == 1)
        #expect(mock.loggedMessages[0] == "Test message")
    }

    @Test("Reset clears all state")
    func resetClearsState() {
        let mock = MockAnalyticsService()
        mock.logEvent(.articleBookmarked)
        mock.recordError(NSError(domain: "test", code: 1), userInfo: nil)
        mock.log("message")
        mock.setUserID("user")
        mock.setUserProperty("val", forName: "prop")

        mock.reset()

        #expect(mock.loggedEvents.isEmpty)
        #expect(mock.recordedErrors.isEmpty)
        #expect(mock.loggedMessages.isEmpty)
        #expect(mock.currentUserID == nil)
        #expect(mock.userProperties.isEmpty)
    }
}
