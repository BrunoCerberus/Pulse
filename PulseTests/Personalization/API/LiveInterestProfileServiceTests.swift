import Combine
import Foundation
@testable import Pulse
import SwiftData
import Testing

@Suite("LiveInterestProfileService Tests")
@MainActor
struct LiveInterestProfileServiceTests {
    private let storageService: LiveStorageService
    private let sut: LiveInterestProfileService

    init() {
        // Share an in-memory ModelContainer with LiveStorageService — same
        // wiring as production, just CloudKit-off and memory-only.
        storageService = LiveStorageService(inMemory: true, enableCloudKit: false)
        sut = LiveInterestProfileService(modelContainer: storageService.modelContainer)
    }

    // MARK: - Upsert

    @Test("Upsert inserts a new topic with weightDelta as initial weight")
    func upsertInsertsNewTopic() async throws {
        try await sut.upsert(
            topicID: "ai",
            displayName: "AI",
            weightDelta: 2.0,
            source: .extracted,
            category: nil,
        )

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
        let first = try #require(profile.first)
        #expect(first.topicID == "ai")
        #expect(first.weight == 2.0)
        #expect(first.source == .extracted)
    }

    @Test("Upsert accumulates weightDelta onto existing topic")
    func upsertAccumulatesWeight() async throws {
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.0, source: .extracted, category: nil,
        )
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 2.5, source: .extracted, category: nil,
        )

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
        #expect(profile.first?.weight == 3.5)
    }

    // MARK: - Deduplication (H8)

    @Test("deduplicate folds duplicate topic rows: keeps earliest, sums weight")
    func deduplicateFoldsDuplicateTopics() async throws {
        // CloudKit can merge two rows with the same topicID from different
        // devices; insert them directly to reproduce that state.
        let context = storageService.modelContainer.mainContext
        let older = InterestTopicModel(from: InterestTopic(
            topicID: "ai", displayName: "AI", weight: 2.0, category: nil,
            lastReinforcedAt: Date(timeIntervalSince1970: 1000),
            createdAt: Date(timeIntervalSince1970: 1000), source: .extracted,
        ))
        let newer = InterestTopicModel(from: InterestTopic(
            topicID: "ai", displayName: "AI", weight: 3.0, category: nil,
            lastReinforcedAt: Date(timeIntervalSince1970: 2000),
            createdAt: Date(timeIntervalSince1970: 2000), source: .extracted,
        ))
        context.insert(older)
        context.insert(newer)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<InterestTopicModel>()).count == 2)

        let changed = try await sut.deduplicate()

        #expect(changed == true)
        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
        #expect(profile.first?.weight == 5.0) // 2.0 + 3.0 folded into survivor
        #expect(profile.first?.createdAt == Date(timeIntervalSince1970: 1000)) // earliest kept
    }

    @Test("deduplicate returns false when topics are unique")
    func deduplicateNoOpWhenUnique() async throws {
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.0, source: .extracted, category: nil,
        )
        let changed = try await sut.deduplicate()
        #expect(changed == false)
    }

    @Test("Upsert preserves original source and createdAt across re-upsert")
    func upsertPreservesOriginalSource() async throws {
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.0, source: .seed, category: NewsCategory.technology.rawValue,
        )
        let originalCreatedAt = try await sut.fetchProfile().first?.createdAt

        // A later .extracted upsert should NOT downgrade source from .seed.
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 0.5, source: .extracted, category: nil,
        )

        let profile = try await sut.fetchProfile()
        #expect(profile.first?.source == .seed)
        #expect(profile.first?.createdAt == originalCreatedAt)
    }

    @Test("Upsert preserves the original displayName across re-upserts")
    func upsertPreservesDisplayName() async throws {
        try await sut.upsert(
            topicID: "ai", displayName: "AI",
            weightDelta: 1.0, source: .seed, category: nil,
        )
        try await sut.upsert(
            topicID: "ai", displayName: "Artificial Intelligence",
            weightDelta: 0.5, source: .extracted, category: nil,
        )
        let profile = try await sut.fetchProfile()
        // Original "AI" wins — onboarding labels shouldn't get flipped
        // every drain by an LLM-derived display name.
        #expect(profile.first?.displayName == "AI")
    }

    @Test("Upsert fills in displayName when the original was empty")
    func upsertFillsEmptyDisplayName() async throws {
        try await sut.upsert(
            topicID: "ai", displayName: "",
            weightDelta: 1.0, source: .seed, category: nil,
        )
        try await sut.upsert(
            topicID: "ai", displayName: "Artificial Intelligence",
            weightDelta: 0.5, source: .extracted, category: nil,
        )
        let profile = try await sut.fetchProfile()
        #expect(profile.first?.displayName == "Artificial Intelligence")
    }

    // MARK: - Fetch ordering

    @Test("fetchProfile returns topics ordered by weight descending")
    func fetchOrderedByWeight() async throws {
        try await sut.upsert(topicID: "low", displayName: "L", weightDelta: 1.0, source: .seed, category: nil)
        try await sut.upsert(topicID: "high", displayName: "H", weightDelta: 5.0, source: .seed, category: nil)
        try await sut.upsert(topicID: "mid", displayName: "M", weightDelta: 2.5, source: .seed, category: nil)

        let profile = try await sut.fetchProfile()
        #expect(profile.map(\.topicID) == ["high", "mid", "low"])
    }

    // MARK: - Remove / Reset

    @Test("Remove deletes the matching topic")
    func removeDeletesTopic() async throws {
        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.upsert(topicID: "b", displayName: "B", weightDelta: 2, source: .seed, category: nil)
        try await sut.remove(topicID: "a")

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
        #expect(profile.first?.topicID == "b")
    }

    @Test("Remove of unknown topic is a no-op")
    func removeUnknownIsNoop() async throws {
        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.remove(topicID: "nonexistent")

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
    }

    @Test("resetProfile wipes every topic")
    func resetProfileWipesEverything() async throws {
        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.upsert(topicID: "b", displayName: "B", weightDelta: 2, source: .seed, category: nil)
        try await sut.resetProfile()

        let profile = try await sut.fetchProfile()
        #expect(profile.isEmpty)
    }

    // MARK: - Seeding

    @Test("seedFromCategories upserts one row per category with source .seed")
    func seedFromCategoriesPopulatesProfile() async throws {
        try await sut.seedFromCategories([.technology, .science, .health])

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 3)
        #expect(profile.allSatisfy { $0.source == .seed })
        #expect(Set(profile.map(\.topicID)) == ["technology", "science", "health"])
        #expect(profile.allSatisfy { $0.weight == 1.0 })
    }

    @Test("Re-seeding accumulates weight on existing seeded topics")
    func reseedingAccumulatesWeight() async throws {
        try await sut.seedFromCategories([.technology])
        try await sut.seedFromCategories([.technology])

        let profile = try await sut.fetchProfile()
        #expect(profile.count == 1)
        #expect(profile.first?.weight == 2.0)
    }

    // MARK: - Change broadcast

    @Test("Mutations emit on profileChangedPublisher")
    func mutationsEmitChangeEvent() async throws {
        var receivedCount = 0
        let cancellable = sut.profileChangedPublisher.sink { _ in
            receivedCount += 1
        }
        defer { cancellable.cancel() }

        try await sut.upsert(topicID: "a", displayName: "A", weightDelta: 1, source: .seed, category: nil)
        try await sut.remove(topicID: "a")
        try await sut.resetProfile()

        // Allow any pending main-actor scheduling to flush.
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedCount >= 3)
    }
}
