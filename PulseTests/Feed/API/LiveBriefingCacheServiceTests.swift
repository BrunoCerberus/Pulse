import Foundation
@testable import Pulse
import Testing

@Suite("LiveBriefingCacheService Tests", .serialized)
struct LiveBriefingCacheServiceTests {
    private let suiteName = "com.pulse.briefingcache.tests"

    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeBriefing(generatedAt: Date) -> PregeneratedBriefing {
        PregeneratedBriefing(
            digest: DailyDigest(id: "d1", summary: "Summary", sourceArticles: [], generatedAt: generatedAt),
            queueArticles: [],
            generatedAt: generatedAt
        )
    }

    @Test("A briefing stored today is returned by fetchIfFreshToday")
    func freshBriefingIsReturned() {
        let sut = LiveBriefingCacheService(defaults: freshDefaults())
        let briefing = makeBriefing(generatedAt: Date())

        sut.store(briefing)

        #expect(sut.fetchIfFreshToday()?.digest.id == "d1")
    }

    @Test("A briefing stored yesterday is treated as stale and returns nil")
    func staleBriefingReturnsNil() throws {
        let sut = LiveBriefingCacheService(defaults: freshDefaults())
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        sut.store(makeBriefing(generatedAt: yesterday))

        #expect(sut.fetchIfFreshToday() == nil)
    }

    @Test("No stored briefing returns nil")
    func noBriefingReturnsNil() {
        let sut = LiveBriefingCacheService(defaults: freshDefaults())

        #expect(sut.fetchIfFreshToday() == nil)
    }

    @Test("Storing a new briefing replaces the previous one")
    func storingReplacesPreviousEntry() {
        let sut = LiveBriefingCacheService(defaults: freshDefaults())
        sut.store(makeBriefing(generatedAt: Date()))
        sut.store(
            PregeneratedBriefing(
                digest: DailyDigest(id: "d2", summary: "Newer", sourceArticles: [], generatedAt: Date()),
                queueArticles: [],
                generatedAt: Date()
            )
        )

        #expect(sut.fetchIfFreshToday()?.digest.id == "d2")
    }
}
