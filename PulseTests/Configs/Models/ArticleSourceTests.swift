import Foundation
@testable import Pulse
import Testing

@Suite("ArticleSource Model Tests")
struct ArticleSourceTests {
    @Test("ArticleSource initializes correctly")
    func initializesCorrectly() {
        let source = ArticleSource(id: "source-id", name: "Source Name")

        #expect(source.id == "source-id")
        #expect(source.name == "Source Name")
    }

    @Test("ArticleSource with nil id")
    func initializesWithNilId() {
        let source = ArticleSource(id: nil, name: "Source Name")

        #expect(source.id == nil)
        #expect(source.name == "Source Name")
    }

    @Test("ArticleSource equality")
    func equalityComparison() {
        let source1 = ArticleSource(id: "id", name: "Name")
        let source2 = ArticleSource(id: "id", name: "Name")
        let source3 = ArticleSource(id: "other", name: "Name")

        #expect(source1 == source2)
        #expect(source1 != source3)
    }

    @Test("ArticleSource encodes and decodes")
    func encodesAndDecodes() throws {
        let source = ArticleSource(id: "test", name: "Test Source")

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ArticleSource.self, from: data)

        #expect(decoded == source)
    }
}
