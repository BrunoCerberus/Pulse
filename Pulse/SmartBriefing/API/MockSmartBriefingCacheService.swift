import Foundation

/// In-memory mock of `SmartBriefingCacheService` for tests / SwiftUI previews.
final class MockSmartBriefingCacheService: SmartBriefingCacheService, @unchecked Sendable {
    private(set) var lastRecordedServedIDs: Set<String>?
    private(set) var lastRecordedServedAt: Date?
    private(set) var recordServedCallCount = 0
    var fetchResult: SmartBriefingServedRecord?

    func recordServed(_ newlyServedArticleIDs: Set<String>, at servedAt: Date) {
        lastRecordedServedIDs = newlyServedArticleIDs
        lastRecordedServedAt = servedAt
        recordServedCallCount += 1
    }

    func fetchLastServed() -> SmartBriefingServedRecord? {
        fetchResult
    }

    func clear() {
        fetchResult = nil
        lastRecordedServedIDs = nil
        lastRecordedServedAt = nil
    }
}
