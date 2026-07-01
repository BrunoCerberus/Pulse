import Foundation

/// In-memory mock of `BriefingCacheService` for tests / SwiftUI previews.
final class MockBriefingCacheService: BriefingCacheService, @unchecked Sendable {
    private(set) var storedBriefing: PregeneratedBriefing?
    private(set) var storeCallCount = 0
    var fetchResult: PregeneratedBriefing?

    func store(_ briefing: PregeneratedBriefing) {
        storedBriefing = briefing
        storeCallCount += 1
    }

    func fetchIfFreshToday() -> PregeneratedBriefing? {
        fetchResult
    }
}
