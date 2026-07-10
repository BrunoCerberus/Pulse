import Foundation

/// In-memory mock of `SmartBriefingCacheService` for tests / SwiftUI previews.
final class MockSmartBriefingCacheService: SmartBriefingCacheService, @unchecked Sendable {
    private(set) var storedRecord: SmartBriefingServedRecord?
    private(set) var storeCallCount = 0
    var fetchResult: SmartBriefingServedRecord?

    func store(_ record: SmartBriefingServedRecord) {
        storedRecord = record
        storeCallCount += 1
    }

    func fetchLastServed() -> SmartBriefingServedRecord? {
        fetchResult
    }

    func clear() {
        fetchResult = nil
        storedRecord = nil
    }
}
