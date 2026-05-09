import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("MockInterestProfileService Tests")
struct MockInterestProfileServiceTests {
    @Test("Upsert inserts a new topic and seeds the source")
    func upsertInserts() async throws {
        let sut = MockInterestProfileService()
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.5, source: .extracted, category: nil
        )
        #expect(sut.topics.count == 1)
        #expect(sut.topics.first?.weight == 1.5)
        #expect(sut.topics.first?.source == .extracted)
    }

    @Test("Upsert accumulates weightDelta and preserves original source")
    func upsertAccumulates() async throws {
        let sut = MockInterestProfileService()
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.0, source: .seed, category: nil
        )
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 2.0, source: .extracted, category: nil
        )
        #expect(sut.topics.first?.weight == 3.0)
        #expect(sut.topics.first?.source == .seed)
    }

    @Test("seedFromCategories adds one row per category")
    func seedFromCategoriesAddsRows() async throws {
        let sut = MockInterestProfileService()
        try await sut.seedFromCategories([.technology, .science])
        #expect(sut.topics.count == 2)
        #expect(sut.topics.allSatisfy { $0.source == .seed })
    }

    @Test("remove deletes the topic")
    func removeDeletes() async throws {
        let sut = MockInterestProfileService()
        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.remove(topicID: "a")
        #expect(sut.topics.isEmpty)
    }

    @Test("resetProfile clears all topics")
    func resetProfileClears() async throws {
        let sut = MockInterestProfileService()
        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.upsert(topicID: "b", displayName: "B", weightDelta: 2, source: .seed, category: nil)
        try await sut.resetProfile()
        #expect(sut.topics.isEmpty)
    }

    @Test("fetchProfileError propagates")
    func fetchProfileSurfacesError() async {
        struct Boom: Error {}
        let sut = MockInterestProfileService()
        sut.fetchProfileError = Boom()
        await #expect(throws: Boom.self) {
            _ = try await sut.fetchProfile()
        }
    }

    @Test("Topics are returned sorted by weight descending")
    func topicsSortedByWeight() async throws {
        let sut = MockInterestProfileService()
        try await sut.upsert(topicID: "small", displayName: "S", weightDelta: 1, source: .seed, category: nil)
        try await sut.upsert(topicID: "big", displayName: "B", weightDelta: 5, source: .seed, category: nil)
        #expect(sut.topics.map(\.topicID) == ["big", "small"])
    }

    @Test("upsertError propagates")
    func upsertSurfacesError() async {
        struct Boom: Error {}
        let sut = MockInterestProfileService()
        sut.upsertError = Boom()

        var thrown: Error?
        do {
            try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        } catch {
            thrown = error
        }
        #expect(thrown is Boom)
    }

    @Test("removeError propagates")
    func removeSurfacesError() async {
        struct Boom: Error {}
        let sut = MockInterestProfileService()
        sut.removeError = Boom()

        var thrown: Error?
        do {
            try await sut.remove(topicID: "anything")
        } catch {
            thrown = error
        }
        #expect(thrown is Boom)
    }

    @Test("resetProfileError propagates")
    func resetSurfacesError() async {
        struct Boom: Error {}
        let sut = MockInterestProfileService()
        sut.resetProfileError = Boom()

        var thrown: Error?
        do {
            try await sut.resetProfile()
        } catch {
            thrown = error
        }
        #expect(thrown is Boom)
    }

    @Test("profileChangedPublisher emits on every mutation")
    func profileChangedPublisherEmits() async throws {
        let sut = MockInterestProfileService()
        var hits = 0
        let cancellable = sut.profileChangedPublisher.sink { _ in
            hits += 1
        }
        defer { cancellable.cancel() }

        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.remove(topicID: "a")
        try await sut.resetProfile()
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(hits >= 3)
    }
}
