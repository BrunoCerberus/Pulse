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

    @Test("A stored record round-trips through fetchLastServed")
    func storeAndFetchRoundTrip() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())
        let record = SmartBriefingServedRecord(servedAt: Date(), servedArticleIDs: ["1", "2", "3"])

        sut.store(record)

        let fetched = sut.fetchLastServed()
        #expect(fetched?.servedArticleIDs == record.servedArticleIDs)
    }

    @Test("No stored record returns nil")
    func noRecordReturnsNil() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        #expect(sut.fetchLastServed() == nil)
    }

    @Test("clear() wipes the stored record")
    func clearWipesRecord() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())
        sut.store(SmartBriefingServedRecord(servedAt: Date(), servedArticleIDs: ["1"]))

        sut.clear()

        #expect(sut.fetchLastServed() == nil)
    }

    @Test("Served IDs accumulate across multiple store calls")
    func servedIDsAccumulate() {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())
        sut.store(SmartBriefingServedRecord(servedAt: Date(), servedArticleIDs: ["1", "2"]))
        sut.store(SmartBriefingServedRecord(servedAt: Date(), servedArticleIDs: ["1", "2", "3"]))

        let fetched = sut.fetchLastServed()
        #expect(fetched?.servedArticleIDs == ["1", "2", "3"])
    }

    @Test("Served ID history is capped, evicting the oldest IDs first")
    func servedIDsAreCappedFIFO() throws {
        let sut = LiveSmartBriefingCacheService(defaults: freshDefaults())

        // Store 501 unique IDs one at a time so insertion order is well-defined.
        for index in 0 ..< 501 {
            sut.store(SmartBriefingServedRecord(servedAt: Date(), servedArticleIDs: ["id-\(index)"]))
        }

        let fetched = try #require(sut.fetchLastServed())
        #expect(fetched.servedArticleIDs.count == 500)
        #expect(!fetched.servedArticleIDs.contains("id-0"))
        #expect(fetched.servedArticleIDs.contains("id-500"))
    }
}
