import Foundation
@testable import Pulse
import Testing
import UIKit

@Suite("QuickActionHandler Tests", .serialized)
@MainActor
struct QuickActionHandlerTests {
    let sut: QuickActionHandler

    init() {
        sut = QuickActionHandler.shared
        sut.clearPending()
    }

    /// Restores the real deeplink handler and clears pending state so other tests don't
    /// inherit a mocked singleton.
    private func resetSingleton() {
        sut.clearPending()
        sut.deeplinkHandler = { DeeplinkManager.shared.handle(deeplink: $0) }
    }

    // MARK: - Routing

    @Test(
        "handle(shortcutItem:) routes each QuickActionType to the correct deeplink",
        arguments: [
            (QuickActionType.search, Deeplink.search(query: nil)),
            (QuickActionType.dailyDigest, Deeplink.feed),
            (QuickActionType.bookmarks, Deeplink.bookmarks),
            (QuickActionType.breakingNews, Deeplink.home),
        ]
    )
    func routesToExpectedDeeplink(type: QuickActionType, expected: Deeplink) {
        defer { resetSingleton() }

        var captured: [Deeplink] = []
        sut.deeplinkHandler = { captured.append($0) }

        let handled = sut.handle(shortcutItem: type.shortcutItem())

        #expect(handled == true)
        #expect(captured == [expected])
        #expect(sut.pendingType == type)
    }

    // MARK: - Pending state

    @Test("pendingType tracks the last handled type")
    func pendingTypeTracksLastHandled() {
        defer { resetSingleton() }

        sut.deeplinkHandler = { _ in }

        _ = sut.handle(shortcutItem: QuickActionType.search.shortcutItem())
        #expect(sut.pendingType == .search)

        _ = sut.handle(shortcutItem: QuickActionType.bookmarks.shortcutItem())
        #expect(sut.pendingType == .bookmarks)
    }

    @Test("clearPending resets pendingType to nil")
    func clearPendingResetsState() {
        defer { resetSingleton() }

        sut.deeplinkHandler = { _ in }
        _ = sut.handle(shortcutItem: QuickActionType.search.shortcutItem())
        #expect(sut.pendingType == .search)

        sut.clearPending()
        #expect(sut.pendingType == nil)
    }

    // MARK: - Unknown shortcut

    @Test("Unknown shortcut type returns false and does not invoke deeplinkHandler")
    func unknownShortcutIsIgnored() {
        defer { resetSingleton() }

        var captured: [Deeplink] = []
        sut.deeplinkHandler = { captured.append($0) }

        let unknown = UIApplicationShortcutItem(
            type: "not.a.real.quick.action",
            localizedTitle: "Nope"
        )
        let handled = sut.handle(shortcutItem: unknown)

        #expect(handled == false)
        #expect(captured.isEmpty)
        #expect(sut.pendingType == nil)
    }
}
