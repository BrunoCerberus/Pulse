import Foundation
@testable import Pulse
import Testing

@Suite("LiveSmartBriefingCacheService Tests", .serialized)
struct LiveSmartBriefingCacheServiceTests {
    private let suiteName = "com.pulse.smartbriefingcache.tests"

    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("A recorded run round-trips through fetchLastServed")
    func recordAndFetchRoundTrip() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        sut.recordServed(["1", "2", "3"], at: Date())

        let fetched = sut.fetchLastServed()
        #expect(fetched?.servedArticleIDs == ["1", "2", "3"])
    }

    @Test("No recorded run returns nil")
    func noRecordReturnsNil() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        #expect(sut.fetchLastServed() == nil)
    }

    @Test("clear() wipes the recorded history")
    func clearWipesRecord() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())
        sut.recordServed(["1"], at: Date())

        sut.clear()

        #expect(sut.fetchLastServed() == nil)
    }

    @Test("Served IDs accumulate across multiple recordServed calls, each passing only the delta")
    func servedIDsAccumulate() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())
        sut.recordServed(["1", "2"], at: Date())
        sut.recordServed(["3"], at: Date())

        let fetched = sut.fetchLastServed()
        #expect(fetched?.servedArticleIDs == ["1", "2", "3"])
    }

    @Test("Served ID history is capped, evicting the oldest IDs first")
    func servedIDsAreCappedFIFO() throws {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        // Record 501 unique IDs one delta at a time so insertion order is well-defined.
        for index in 0 ..< 501 {
            sut.recordServed(["id-\(index)"], at: Date())
        }

        let fetched = try #require(sut.fetchLastServed())
        #expect(fetched.servedArticleIDs.count == 500)
        #expect(!fetched.servedArticleIDs.contains("id-0"))
        #expect(fetched.servedArticleIDs.contains("id-500"))
    }

    @Test("FIFO order survives the real production call pattern: passing only the newly-served delta each run")
    func fifoOrderSurvivesRealisticDeltaOnlyUsage() throws {
        // Regression test for the bug flagged in review: the interactor used
        // to pass the *entire accumulated* union of served IDs on every call
        // (re-deriving order from a Set, which isn't stable), which silently
        // destroyed true insertion order. The production caller now passes
        // only this run's newly-served IDs — verify the cap still evicts the
        // truly oldest IDs first across many such runs.
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        // 50 runs of 11 newly-served articles each = 550 total IDs, capped at 500.
        for run in 0 ..< 50 {
            let runIDs = Set((0 ..< 11).map { "run-\(run)-article-\($0)" })
            sut.recordServed(runIDs, at: Date())
        }

        let fetched = try #require(sut.fetchLastServed())
        #expect(fetched.servedArticleIDs.count == 500)
        // The earliest 5 runs (55 IDs) should have been evicted first.
        for run in 0 ..< 5 {
            #expect(!fetched.servedArticleIDs.contains("run-\(run)-article-0"))
        }
        // The most recent runs must still be present.
        for run in 45 ..< 50 {
            #expect(fetched.servedArticleIDs.contains("run-\(run)-article-0"))
        }
    }
}
