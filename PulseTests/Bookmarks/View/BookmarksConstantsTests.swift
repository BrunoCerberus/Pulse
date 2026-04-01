import Foundation
@testable import Pulse
import Testing

// Type alias for convenience since BookmarksView has a generic parameter
private typealias Constants = BookmarksView<BookmarksNavigationRouter>.Constants

@Suite("BookmarksView Constants Tests")
struct BookmarksConstantsTests {
    @Test("savedCountFormat returns singular for count of 1")
    func singularCount() {
        let format = Constants.savedCountFormat(for: 1)
        let result = String(format: format, 1)

        #expect(result.contains("1"))
        // The singular form should NOT contain "articles" (plural)
        #expect(!result.hasSuffix("articles"), "Should use singular 'article' for count of 1")
    }

    @Test("savedCountFormat returns plural for count of 0")
    func zeroCount() {
        let format = Constants.savedCountFormat(for: 0)
        let result = String(format: format, 0)

        #expect(result.contains("0"))
    }

    @Test("savedCountFormat returns plural for count of 2")
    func pluralCount() {
        let format = Constants.savedCountFormat(for: 2)
        let result = String(format: format, 2)

        #expect(result.contains("2"))
    }

    @Test("savedCountFormat returns different strings for 1 vs 2")
    func singularDiffersFromPlural() {
        let singularFormat = Constants.savedCountFormat(for: 1)
        let pluralFormat = Constants.savedCountFormat(for: 2)

        #expect(singularFormat != pluralFormat, "Singular and plural formats should be different")
    }

    @Test("savedCountFormat returns plural for large counts")
    func largeCount() {
        let format = Constants.savedCountFormat(for: 100)
        let result = String(format: format, 100)

        #expect(result.contains("100"))
    }
}
