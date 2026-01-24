import Foundation
import Testing

@testable import Pulse

@Suite
struct NotificationDeeplinkParserTests {
    // MARK: - Format 1: Full Deeplink URL

    @Test("Parse full deeplink URL - home")
    func parseFullDeeplinkURLHome() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://home"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .home)
    }

    @Test("Parse full deeplink URL - feed")
    func parseFullDeeplinkURLFeed() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://feed"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .feed)
    }

    @Test("Parse full deeplink URL - bookmarks")
    func parseFullDeeplinkURLBookmarks() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://bookmarks"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .bookmarks)
    }

    @Test("Parse full deeplink URL - settings")
    func parseFullDeeplinkURLSettings() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://settings"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .settings)
    }

    @Test("Parse full deeplink URL - search without query")
    func parseFullDeeplinkURLSearchNoQuery() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://search"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .search(query: nil))
    }

    @Test("Parse full deeplink URL - search with query")
    func parseFullDeeplinkURLSearchWithQuery() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://search?q=swift"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .search(query: "swift"))
    }

    @Test("Parse full deeplink URL - article with id")
    func parseFullDeeplinkURLArticle() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://article?id=world/2024/jan/01/article-slug"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "world/2024/jan/01/article-slug"))
    }

    @Test("Parse full deeplink URL - article without id returns nil")
    func parseFullDeeplinkURLArticleNoId() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://article"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Parse full deeplink URL - invalid scheme returns nil")
    func parseFullDeeplinkURLInvalidScheme() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "https://example.com"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Parse full deeplink URL - unknown host returns nil")
    func parseFullDeeplinkURLUnknownHost() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://unknown"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Parse full deeplink URL - invalid URL returns nil")
    func parseFullDeeplinkURLInvalidURL() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "not a valid url"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    // MARK: - Format 2: Legacy articleID

    @Test("Parse legacy articleID")
    func parseLegacyArticleID() {
        let userInfo: [AnyHashable: Any] = ["articleID": "world/2024/jan/01/article-slug"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "world/2024/jan/01/article-slug"))
    }

    @Test("Parse legacy articleID - empty string")
    func parseLegacyArticleIDEmpty() {
        let userInfo: [AnyHashable: Any] = ["articleID": ""]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: ""))
    }

    // MARK: - Format 3: Type-based

    @Test("Parse typed deeplink - home")
    func parseTypedDeeplinkHome() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "home"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .home)
    }

    @Test("Parse typed deeplink - feed")
    func parseTypedDeeplinkFeed() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "feed"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .feed)
    }

    @Test("Parse typed deeplink - bookmarks")
    func parseTypedDeeplinkBookmarks() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "bookmarks"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .bookmarks)
    }

    @Test("Parse typed deeplink - settings")
    func parseTypedDeeplinkSettings() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "settings"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .settings)
    }

    @Test("Parse typed deeplink - search without query")
    func parseTypedDeeplinkSearchNoQuery() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "search"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .search(query: nil))
    }

    @Test("Parse typed deeplink - search with query")
    func parseTypedDeeplinkSearchWithQuery() {
        let userInfo: [AnyHashable: Any] = [
            "deeplinkType": "search",
            "deeplinkQuery": "swift concurrency",
        ]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .search(query: "swift concurrency"))
    }

    @Test("Parse typed deeplink - article with id")
    func parseTypedDeeplinkArticle() {
        let userInfo: [AnyHashable: Any] = [
            "deeplinkType": "article",
            "deeplinkId": "world/2024/jan/01/article-slug",
        ]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "world/2024/jan/01/article-slug"))
    }

    @Test("Parse typed deeplink - article without id returns nil")
    func parseTypedDeeplinkArticleNoId() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "article"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Parse typed deeplink - unknown type returns nil")
    func parseTypedDeeplinkUnknownType() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "unknown"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    // MARK: - Priority Tests

    @Test("Full deeplink URL takes priority over articleID")
    func priorityDeeplinkURLOverArticleID() {
        let userInfo: [AnyHashable: Any] = [
            "deeplink": "pulse://home",
            "articleID": "world/2024/jan/01/article-slug",
        ]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .home)
    }

    @Test("Full deeplink URL takes priority over deeplinkType")
    func priorityDeeplinkURLOverDeeplinkType() {
        let userInfo: [AnyHashable: Any] = [
            "deeplink": "pulse://search?q=test",
            "deeplinkType": "home",
        ]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .search(query: "test"))
    }

    @Test("articleID takes priority over deeplinkType")
    func priorityArticleIDOverDeeplinkType() {
        let userInfo: [AnyHashable: Any] = [
            "articleID": "world/2024/jan/01/article-slug",
            "deeplinkType": "home",
        ]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "world/2024/jan/01/article-slug"))
    }

    // MARK: - Edge Cases

    @Test("Empty userInfo returns nil")
    func emptyUserInfoReturnsNil() {
        let userInfo: [AnyHashable: Any] = [:]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Non-string deeplink value returns nil")
    func nonStringDeeplinkReturnsNil() {
        let userInfo: [AnyHashable: Any] = ["deeplink": 123]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Non-string articleID value returns nil")
    func nonStringArticleIDReturnsNil() {
        let userInfo: [AnyHashable: Any] = ["articleID": 123]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    @Test("Non-string deeplinkType value returns nil")
    func nonStringDeeplinkTypeReturnsNil() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": 123]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == nil)
    }

    // MARK: - Direct parseURL Tests

    @Test("parseURL with valid home URL")
    func parseURLHome() {
        let url = URL(string: "pulse://home")!
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .home)
    }

    @Test("parseURL with non-pulse scheme returns nil")
    func parseURLNonPulseScheme() {
        let url = URL(string: "https://example.com/home")!
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == nil)
    }

    // MARK: - Direct parseTyped Tests

    @Test("parseTyped with valid type and userInfo")
    func parseTypedValid() {
        let userInfo: [AnyHashable: Any] = ["deeplinkQuery": "ios development"]
        let result = NotificationDeeplinkParser.parseTyped(type: "search", userInfo: userInfo)
        #expect(result == .search(query: "ios development"))
    }

    @Test("parseTyped with unknown type returns nil")
    func parseTypedUnknown() {
        let userInfo: [AnyHashable: Any] = [:]
        let result = NotificationDeeplinkParser.parseTyped(type: "invalid", userInfo: userInfo)
        #expect(result == nil)
    }
}
