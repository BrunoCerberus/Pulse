import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("DeeplinkManager Tests", .serialized)
struct DeeplinkManagerTests {
    let sut: DeeplinkManager

    init() {
        sut = DeeplinkManager.shared
        sut.clearDeeplink()
    }

    @Test("Parse home deeplink")
    func parseHomeDeeplink() {
        let url = URL(string: "pulse://home")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .home)
    }

    @Test("Parse search deeplink with query")
    func parseSearchDeeplinkWithQuery() {
        let url = URL(string: "pulse://search?q=swift")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .search(query: "swift"))
    }

    @Test("Parse search deeplink without query")
    func parseSearchDeeplinkWithoutQuery() {
        let url = URL(string: "pulse://search")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .search(query: nil))
    }

    @Test("Parse bookmarks deeplink")
    func parseBookmarksDeeplink() {
        let url = URL(string: "pulse://bookmarks")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .bookmarks)
    }

    @Test("Parse settings deeplink")
    func parseSettingsDeeplink() {
        let url = URL(string: "pulse://settings")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .settings)
    }

    @Test("Parse article deeplink")
    func parseArticleDeeplink() {
        let url = URL(string: "pulse://article?id=123")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .article(id: "123"))
    }

    @Test("Parse category deeplink")
    func parseCategoryDeeplink() {
        let url = URL(string: "pulse://category?name=technology")!

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .category(name: "technology"))
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
