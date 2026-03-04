import EntropyCore
import Foundation
@testable import Pulse
import Testing

struct BaseURLsTests {
    @Test("guardianAPI returns correct URL")
    func guardianAPIReturnsCorrectURL() {
        #expect(BaseURLs.guardianAPI == "https://content.guardianapis.com")
    }
}
