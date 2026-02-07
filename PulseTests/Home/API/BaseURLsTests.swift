import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("BaseURLs Tests")
struct BaseURLsTests {
    @Test("newsAPI returns correct URL")
    func newsAPIReturnsCorrectURL() {
        #expect(BaseURLs.newsAPI == "https://newsapi.org/v2")
    }

    @Test("guardianAPI returns correct URL")
    func guardianAPIReturnsCorrectURL() {
        #expect(BaseURLs.guardianAPI == "https://content.guardianapis.com")
    }

    @Test("gnewsAPI returns correct URL")
    func gnewsAPIReturnsCorrectURL() {
        #expect(BaseURLs.gnewsAPI == "https://gnews.io/api/v4")
    }
}
