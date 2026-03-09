import Combine
import Foundation

/// Mock implementation of `StoryThreadService` for testing and previews.
final class MockStoryThreadService: StoryThreadService {
    // MARK: - Configurable Results

    var fetchThreadsResult: Result<[StoryThread], Error> = .success([])
    var followedThreadsResult: Result<[StoryThread], Error> = .success([])
    var followResult: Result<Void, Error> = .success(())
    var unfollowResult: Result<Void, Error> = .success(())
    var generateSummaryResult: Result<String, Error> = .success("AI-generated summary of the story so far.")
    var clusterResult: Result<[StoryThread], Error> = .success([])
    var markAsReadResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    var fetchThreadsCallCount = 0
    var fetchFollowedCallCount = 0
    var followCallCount = 0
    var unfollowCallCount = 0
    var generateSummaryCallCount = 0
    var clusterCallCount = 0
    var markAsReadCallCount = 0
    var lastFollowedID: UUID?
    var lastUnfollowedID: UUID?
    var lastMarkedReadID: UUID?

    // MARK: - StoryThreadService

    func fetchThreads(for _: String) -> AnyPublisher<[StoryThread], Error> {
        fetchThreadsCallCount += 1
        return fetchThreadsResult.publisher.eraseToAnyPublisher()
    }

    func fetchFollowedThreads() -> AnyPublisher<[StoryThread], Error> {
        fetchFollowedCallCount += 1
        return followedThreadsResult.publisher.eraseToAnyPublisher()
    }

    func followThread(id: UUID) -> AnyPublisher<Void, Error> {
        followCallCount += 1
        lastFollowedID = id
        return followResult.publisher.eraseToAnyPublisher()
    }

    func unfollowThread(id: UUID) -> AnyPublisher<Void, Error> {
        unfollowCallCount += 1
        lastUnfollowedID = id
        return unfollowResult.publisher.eraseToAnyPublisher()
    }

    func generateThreadSummary(thread _: StoryThread) -> AnyPublisher<String, Error> {
        generateSummaryCallCount += 1
        return generateSummaryResult.publisher.eraseToAnyPublisher()
    }

    func clusterArticles(from _: [Article]) -> AnyPublisher<[StoryThread], Error> {
        clusterCallCount += 1
        return clusterResult.publisher.eraseToAnyPublisher()
    }

    func markThreadAsRead(id: UUID) -> AnyPublisher<Void, Error> {
        markAsReadCallCount += 1
        lastMarkedReadID = id
        return markAsReadResult.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Sample Data

extension MockStoryThreadService {
    static func withSampleData() -> MockStoryThreadService {
        let service = MockStoryThreadService()
        service.followedThreadsResult = .success(StoryThread.sampleThreads)
        service.fetchThreadsResult = .success([StoryThread.sampleThreads[0]])
        return service
    }
}

extension StoryThread {
    static let sampleID1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let sampleID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let sampleID3 = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    static var sampleThreads: [StoryThread] {
        [
            StoryThread(
                id: sampleID1,
                title: "Ukraine Peace Negotiations",
                summary: "Ongoing diplomatic efforts to resolve the conflict through multilateral talks.",
                articleIDs: ["article-1", "article-2", "article-3", "article-4", "article-5"],
                category: "world",
                isFollowing: true,
                createdAt: Date.now.addingTimeInterval(-86400 * 5),
                updatedAt: Date.now.addingTimeInterval(-3600),
                lastReadAt: Date.now.addingTimeInterval(-86400)
            ),
            StoryThread(
                id: sampleID2,
                title: "AI Regulation Framework",
                summary: "Global efforts to establish regulatory frameworks for artificial intelligence.",
                articleIDs: ["article-6", "article-7", "article-8"],
                category: "technology",
                isFollowing: true,
                createdAt: Date.now.addingTimeInterval(-86400 * 3),
                updatedAt: Date.now.addingTimeInterval(-7200)
            ),
            StoryThread(
                id: sampleID3,
                title: "Climate Summit Progress",
                summary: "Updates from the international climate conference and new commitments.",
                articleIDs: ["article-9", "article-10"],
                category: "science",
                isFollowing: true,
                createdAt: Date.now.addingTimeInterval(-86400 * 2),
                updatedAt: Date.now.addingTimeInterval(-86400)
            ),
        ]
    }
}
