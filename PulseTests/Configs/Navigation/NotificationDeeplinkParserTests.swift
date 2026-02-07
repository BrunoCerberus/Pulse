import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("NotificationDeeplinkParser Tests")
struct NotificationDeeplinkParserTests {
    @Test("parse returns nil for empty userInfo")
    func parseReturnsNilForEmptyUserInfo() {
        let result = NotificationDeeplinkParser.parse(from: [:])
        #expect(result == nil)
    }

    @Test("parseURL parses home deeplink")
    func parseURLParsesHomeDeeplink() throws {
        let url = try #require(URL(string: "pulse://home"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .home)
    }

    @Test("parseURL parses feed deeplink")
    func parseURLParsesFeedDeeplink() throws {
        let url = try #require(URL(string: "pulse://feed"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .feed)
    }

    @Test("parseURL parses bookmarks deeplink")
    func parseURLParsesBookmarksDeeplink() throws {
        let url = try #require(URL(string: "pulse://bookmarks"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .bookmarks)
    }

    @Test("parseURL parses settings deeplink")
    func parseURLParsesSettingsDeeplink() throws {
        let url = try #require(URL(string: "pulse://settings"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .settings)
    }

    @Test("parseURL parses search deeplink with query")
    func parseURLParsesSearchDeeplink() throws {
        let url = try #require(URL(string: "pulse://search?q=swift"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .search(query: "swift"))
    }

    @Test("parseURL parses article deeplink")
    func parseURLParsesArticleDeeplink() throws {
        let url = try #require(URL(string: "pulse://article?id=test/article"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parseURL returns nil for invalid scheme")
    func parseURLReturnsNilForInvalidScheme() throws {
        let url = try #require(URL(string: "https://example.com"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == nil)
    }

    @Test("parseTyped parses home type")
    func parseTypedParsesHomeType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "home", userInfo: [:])
        #expect(result == .home)
    }

    @Test("parseTyped parses feed type")
    func parseTypedParsesFeedType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "feed", userInfo: [:])
        #expect(result == .feed)
    }

    @Test("parseTyped parses search type with query")
    func parseTypedParsesSearchType() {
        let userInfo: [AnyHashable: Any] = ["deeplinkQuery": "swift"]
        let result = NotificationDeeplinkParser.parseTyped(type: "search", userInfo: userInfo)
        #expect(result == .search(query: "swift"))
    }

    @Test("parseTyped parses article type")
    func parseTypedParsesArticleType() {
        let userInfo: [AnyHashable: Any] = ["deeplinkId": "test/article"]
        let result = NotificationDeeplinkParser.parseTyped(type: "article", userInfo: userInfo)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parseTyped returns nil for invalid type")
    func parseTypedReturnsNilForInvalidType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "invalid", userInfo: [:])
        #expect(result == nil)
    }

    @Test("parse parses full URL format")
    func parseParsesFullURLFormat() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://home"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .home)
    }

    @Test("parse parses legacy articleID format")
    func parseParsesLegacyArticleIDFormat() {
        let userInfo: [AnyHashable: Any] = ["articleID": "test/article"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parse parses typed format")
    func parseParsesTypedFormat() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "feed"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .feed)
    }
}
