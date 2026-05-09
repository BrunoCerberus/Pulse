import Foundation
@testable import Pulse
import Testing

@Suite("TopicExtractionDrainer Tests")
@MainActor
struct TopicExtractionDrainerTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeEvent(
        articleID: String = "a",
        title: String = "Article",
        kind: EngagementEvent.Kind = .read30s,
        offset: TimeInterval = 0
    ) -> EngagementEvent {
        EngagementEvent(
            id: UUID(),
            articleID: articleID,
            articleTitle: title,
            articleSummary: "Summary",
            categoryRaw: NewsCategory.technology.rawValue,
            kind: kind,
            weight: nil,
            occurredAt: Self.baseDate.addingTimeInterval(offset)
        )
    }

    private struct Setup {
        let engagement: MockEngagementEventsService
        let extraction: MockTopicExtractionService
        let profile: MockInterestProfileService
        let sut: TopicExtractionDrainer
    }

    private func makeSetup() -> Setup {
        let engagement = MockEngagementEventsService()
        let extraction = MockTopicExtractionService()
        let profile = MockInterestProfileService()
        let drainer = TopicExtractionDrainer(
            engagementService: engagement,
            extractionService: extraction,
            profileService: profile
        )
        return Setup(engagement: engagement, extraction: extraction, profile: profile, sut: drainer)
    }

    @Test("Drain extracts topics and applies them to the profile")
    func drainExtractsAndApplies() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success(["technology", "ai"])
        await setup.engagement.record(makeEvent(articleID: "a"))

        await setup.sut.drainNow()

        // Per-tag weight = event.weight (1.0 for .read30s) / 2 tags = 0.5
        #expect(setup.profile.topics.count == 2)
        let weights = Dictionary(uniqueKeysWithValues: setup.profile.topics.map { ($0.topicID, $0.weight) })
        #expect(weights["technology"] == 0.5)
        #expect(weights["ai"] == 0.5)
        #expect(setup.profile.topics.allSatisfy { $0.source == .extracted })
    }

    @Test("Drain marks events processed after successful extraction")
    func drainMarksProcessed() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success(["t1", "t2"])
        await setup.engagement.record(makeEvent())
        await setup.engagement.record(makeEvent(articleID: "b"))

        await setup.sut.drainNow()

        #expect(setup.engagement.recordedEvents.isEmpty)
    }

    @Test("Drain bails when no events are pending")
    func drainBailsOnEmptyQueue() async {
        let setup = makeSetup()
        await setup.sut.drainNow()
        #expect(setup.extraction.extractCalls.isEmpty)
    }

    @Test("Drain bails when model is not available, leaving events queued")
    func drainBailsWhenModelUnavailable() async {
        let setup = makeSetup()
        setup.extraction.modelAvailable = false
        await setup.engagement.record(makeEvent())
        await setup.engagement.record(makeEvent(articleID: "b"))

        await setup.sut.drainNow()

        #expect(setup.extraction.extractCalls.isEmpty)
        #expect(setup.engagement.recordedEvents.count == 2)
        #expect(setup.profile.topics.isEmpty)
    }

    @Test("Memory pressure stops the batch and leaves remaining events queued")
    func memoryPressureHaltsBatch() async {
        let setup = makeSetup()
        setup.extraction.resultsByTitle = [
            "First": .success(["a", "b"]),
            "Second": .failure(LLMError.memoryPressure),
            "Third": .success(["c"]),
        ]

        await setup.engagement.record(makeEvent(articleID: "1", title: "First", offset: 0))
        await setup.engagement.record(makeEvent(articleID: "2", title: "Second", offset: 60))
        await setup.engagement.record(makeEvent(articleID: "3", title: "Third", offset: 120))

        await setup.sut.drainNow()

        // First was processed; Second hit memory pressure, halting the batch;
        // Third was never reached.
        #expect(setup.engagement.recordedEvents.count == 2)
        #expect(Set(setup.engagement.recordedEvents.map(\.articleID)) == ["2", "3"])
        // Profile only got the First event's tags.
        #expect(Set(setup.profile.topics.map(\.topicID)) == ["a", "b"])
    }

    @Test("Non-memory-pressure errors mark the offending event processed (poison-pill avoidance)")
    func poisonPillEventsAreDropped() async {
        struct Boom: Error {}
        let setup = makeSetup()
        setup.extraction.resultsByTitle = [
            "Good": .success(["t1"]),
            "Poison": .failure(Boom()),
        ]

        await setup.engagement.record(makeEvent(articleID: "1", title: "Good"))
        await setup.engagement.record(makeEvent(articleID: "2", title: "Poison", offset: 60))

        await setup.sut.drainNow()

        // Both events were processed (Poison was dropped to avoid an
        // infinite-retry loop).
        #expect(setup.engagement.recordedEvents.isEmpty)
        // Only the good event contributed tags.
        #expect(setup.profile.topics.map(\.topicID) == ["t1"])
    }

    @Test("Empty tag result still marks the event as processed")
    func emptyTagsStillMarksProcessed() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success([])
        await setup.engagement.record(makeEvent())

        await setup.sut.drainNow()

        #expect(setup.engagement.recordedEvents.isEmpty)
        #expect(setup.profile.topics.isEmpty)
    }

    @Test("Each engagement event divides its weight evenly across its extracted tags")
    func weightDistributedAcrossTags() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success(["a", "b", "c", "d"])
        // .shared has default weight 4.0 → 4.0 / 4 tags = 1.0 each
        await setup.engagement.record(makeEvent(kind: .shared))

        await setup.sut.drainNow()

        let weights = setup.profile.topics.map(\.weight)
        #expect(weights.allSatisfy { abs($0 - 1.0) < 0.0001 })
    }

    @Test("Bookmarked event distributes its 3.0 weight equally")
    func bookmarkedWeightDistributed() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success(["a", "b", "c"])
        await setup.engagement.record(makeEvent(kind: .bookmarked))

        await setup.sut.drainNow()

        let weights = Dictionary(uniqueKeysWithValues: setup.profile.topics.map { ($0.topicID, $0.weight) })
        #expect(abs((weights["a"] ?? 0) - 1.0) < 0.0001)
        #expect(abs((weights["b"] ?? 0) - 1.0) < 0.0001)
        #expect(abs((weights["c"] ?? 0) - 1.0) < 0.0001)
    }

    @Test("Drain processes events in oldest-first order")
    func drainProcessesOldestFirst() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success([])
        await setup.engagement.record(makeEvent(articleID: "newer", title: "Newer", offset: 60))
        await setup.engagement.record(makeEvent(articleID: "older", title: "Older", offset: 0))

        await setup.sut.drainNow()

        #expect(setup.extraction.extractCalls.map(\.title) == ["Older", "Newer"])
    }

    @Test("batchSize caps how many events are processed per drain")
    func batchSizeLimitsBatch() async {
        let setup = makeSetup()
        setup.extraction.extractionResult = .success([])
        for index in 0 ..< 5 {
            await setup.engagement.record(makeEvent(articleID: "a-\(index)", offset: TimeInterval(index)))
        }

        await setup.sut.drainNow(batchSize: 2)

        #expect(setup.extraction.extractCalls.count == 2)
        #expect(setup.engagement.recordedEvents.count == 3)
    }
}
