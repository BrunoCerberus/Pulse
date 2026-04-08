import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("QuickActionType Tests")
@MainActor
struct QuickActionTypeTests {
    // MARK: - shortcutType

    @Test(
        "shortcutType returns bundle-prefixed identifier for each case",
        arguments: [
            (QuickActionType.search, "com.bruno.Pulse-News.quickaction.search"),
            (QuickActionType.dailyDigest, "com.bruno.Pulse-News.quickaction.dailyDigest"),
            (QuickActionType.bookmarks, "com.bruno.Pulse-News.quickaction.bookmarks"),
            (QuickActionType.breakingNews, "com.bruno.Pulse-News.quickaction.breakingNews"),
        ]
    )
    func shortcutType(type: QuickActionType, expected: String) {
        #expect(type.shortcutType == expected)
    }

    // MARK: - systemImageName

    @Test(
        "systemImageName returns the expected SF Symbol for each case",
        arguments: [
            (QuickActionType.search, "magnifyingglass"),
            (QuickActionType.dailyDigest, "text.document"),
            (QuickActionType.bookmarks, "bookmark.fill"),
            (QuickActionType.breakingNews, "bolt.fill"),
        ]
    )
    func systemImageName(type: QuickActionType, expected: String) {
        #expect(type.systemImageName == expected)
    }

    // MARK: - Round-trip

    @Test("Round-trip: QuickActionType -> shortcutItem -> QuickActionType succeeds for every case")
    func roundTripShortcutItem() {
        for type in QuickActionType.allCases {
            let item = type.shortcutItem()
            let parsed = QuickActionType(shortcutItem: item)
            #expect(parsed == type)
        }
    }

    // MARK: - Unknown shortcut item

    @Test("QuickActionType(shortcutItem:) returns nil for unknown type strings")
    func unknownShortcutItemReturnsNil() {
        let unknown = UIApplicationShortcutItem(
            type: "other.type",
            localizedTitle: "Other"
        )
        #expect(QuickActionType(shortcutItem: unknown) == nil)
    }

    // MARK: - shortcutItem()

    @Test("shortcutItem() produces items with correct type, non-empty title, and non-nil icon")
    func shortcutItemProducesValidItem() {
        for type in QuickActionType.allCases {
            let item = type.shortcutItem()
            #expect(item.type == type.shortcutType)
            #expect(!item.localizedTitle.isEmpty)
            #expect(item.icon != nil)
        }
    }
}
