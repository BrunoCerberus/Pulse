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
            ("pulse://feed", Deeplink.feed),
            ("pulse://settings", Deeplink.settings),
            ("pulse://search", Deeplink.search(query: nil)),
            ("pulse://search?q=swift", Deeplink.search(query: "swift")),
            ("pulse://article?id=123", Deeplink.article(id: "123")),
            ("pulse://category?name=technology", Deeplink.category(name: "technology")),
            ("pulse://shared", Deeplink.sharedURLs),
        ]
    )
    func parseDeeplinkCorrectly(urlString: String, expectedDeeplink: Deeplink) throws {
        let url = try #require(URL(string: urlString))

        sut.parse(url: url)

        #expect(sut.currentDeeplink == expectedDeeplink)
        sut.clearDeeplink()
    }

    // MARK: - Free-text Parameter Sanitization

    @Test("Search query with internal spaces is preserved")
    func searchQueryPreservesSpaces() throws {
        let url = try #require(URL(string: "pulse://search?q=swift%20concurrency"))

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .search(query: "swift concurrency"))
    }

    @Test("Search query strips control characters (newline/tab/null)")
    func searchQueryStripsControlCharacters() throws {
        // %0A newline, %09 tab, %00 null injected around the term.
        let url = try #require(URL(string: "pulse://search?q=%0A%09swift%00news%0A"))

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .search(query: "swiftnews"))
    }

    @Test("Whitespace-only search query collapses to nil")
    func searchQueryWhitespaceOnlyIsNil() throws {
        let url = try #require(URL(string: "pulse://search?q=%20%20%20"))

        sut.parse(url: url)

        #expect(sut.currentDeeplink == .search(query: nil))
    }

    @Test("Overlong search query is capped at 256 characters")
    func searchQueryIsLengthCapped() throws {
        let long = String(repeating: "a", count: 1000)
        let url = try #require(URL(string: "pulse://search?q=\(long)"))

        sut.parse(url: url)

        if case let .search(query) = sut.currentDeeplink {
            #expect(query?.count == 256)
        } else {
            Issue.record("Expected .search deeplink, got \(String(describing: sut.currentDeeplink))")
        }
    }

    @Test("Category name with only control characters is rejected")
    func categoryNameControlOnlyIsRejected() throws {
        let url = try #require(URL(string: "pulse://category?name=%0A%09"))

        sut.parse(url: url)

        #expect(sut.currentDeeplink == nil)
    }

    @Test("handle() sanitizes directly-constructed search deeplinks (choke point)")
    func handleSanitizesDirectSearch() {
        sut.handle(deeplink: .search(query: "swift\u{0000}\nnews"))

        #expect(sut.currentDeeplink == .search(query: "swiftnews"))
    }

    @Test("handle() collapses a whitespace-only direct search query to nil")
    func handleCollapsesBlankDirectSearch() {
        sut.handle(deeplink: .search(query: "   "))

        #expect(sut.currentDeeplink == .search(query: nil))
    }

    @Test("SearchPulseIntent routes its query through the sanitizing choke point")
    func searchIntentSanitizesQuery() async throws {
        let intent = SearchPulseIntent()
        intent.query = "climate\nchange\u{0000}"

        _ = try await intent.perform()

        #expect(sut.currentDeeplink == .search(query: "climatechange"))
    }

    @Test("Invalid scheme is ignored")
    func invalidSchemeIsIgnored() throws {
        let url = try #require(URL(string: "invalid://home"))

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
