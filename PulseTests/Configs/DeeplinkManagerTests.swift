import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("DeeplinkManager Tests", .serialized)
@MainActor
struct DeeplinkManagerTests {
    let sut: DeeplinkManager

    init() {
        sut = DeeplinkManager.shared
        sut.clearDeeplink()
    }

    // MARK: - Deeplink Parsing Tests (Consolidated)

    @Test(
        "Parse deeplinks correctly",
        arguments: [
            ("pulse://home", Deeplink.home),
            ("pulse://bookmarks", Deeplink.bookmarks),
            ("pulse://settings", Deeplink.settings),
            ("pulse://search", Deeplink.search(query: nil)),
            ("pulse://search?q=swift", Deeplink.search(query: "swift")),
            ("pulse://article?id=123", Deeplink.article(id: "123")),
            ("pulse://category?name=technology", Deeplink.category(name: "technology")),
        ]
    )
    func parseDeeplinkCorrectly(urlString: String, expectedDeeplink: Deeplink) {
        let url = URL(string: urlString)!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == expectedDeeplink)
        sut.clearDeeplink()
    }

    @Test("Invalid scheme is ignored")
    func invalidSchemeIsIgnored() {
        let url = URL(string: "invalid://home")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == nil)
    }

    @Test("Handle deeplink publishes to publisher")
    func handleDeeplinkPublishes() async throws {
        var cancellables = Set<AnyCancellable>()
        var receivedDeeplinks: [Deeplink] = []

        sut.deeplinkPublisher
            .sink { deeplink in
                receivedDeeplinks.append(deeplink)
            }
            .store(in: &cancellables)

        sut.handle(deeplink: .home)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedDeeplinks.contains(.home))
    }

    @Test("Clear deeplink resets current deeplink")
    func testClearDeeplink() {
        sut.handle(deeplink: .home)
        #expect(sut.currentDeeplink == .home)

        sut.clearDeeplink()
        #expect(sut.currentDeeplink == nil)
    }
}
