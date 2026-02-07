import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("DeeplinkManager Tests")
@MainActor
struct DeeplinkManagerTests {
    @Test("shared returns singleton")
    func sharedReturnsSingleton() {
        let manager1 = DeeplinkManager.shared
        let manager2 = DeeplinkManager.shared
        #expect(manager1 === manager2)
    }

    @Test("handle sends deeplink to publisher")
    func handleSendsDeeplinkToPublisher() async throws {
        let manager = DeeplinkManager()
        var receivedDeeplink: Deeplink?

        let cancellable = manager.deeplinkPublisher.sink { deeplink in
            receivedDeeplink = deeplink
        }

        let deeplink: Deeplink = .home
        manager.handle(deeplink: deeplink)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedDeeplink == .home)

        cancellable.cancel()
    }

    @Test("clearDeeplink clears current deeplink")
    func clearDeeplinkClearsCurrentDeeplink() {
        let manager = DeeplinkManager()
        manager.handle(deeplink: .home)
        manager.clearDeeplink()
        #expect(manager.currentDeeplink == nil)
    }
}
