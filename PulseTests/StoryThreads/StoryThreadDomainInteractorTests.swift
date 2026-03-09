import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadDomainInteractor Tests")
@MainActor
struct StoryThreadDomainInteractorTests {
    let mockService: MockStoryThreadService
    let mockAnalytics: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: StoryThreadDomainInteractor

    init() {
        mockService = MockStoryThreadService()
        mockAnalytics = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StoryThreadService.self, instance: mockService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalytics)
        sut = StoryThreadDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.threads.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
        #expect(state.selectedThreadID == nil)
        #expect(state.generatingSummaryForID == nil)
    }

    @Test("Load followed threads updates state with threads")
    func loadFollowedThreads() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)

        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.threads.count == 3)
        #expect(state.error == nil)
        #expect(mockService.fetchFollowedCallCount == 1)
    }

    @Test("Load followed threads handles error")
    func loadFollowedThreadsError() async throws {
        mockService.followedThreadsResult = .failure(StoryThreadError.threadNotFound)

        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.threads.isEmpty)
        #expect(state.error != nil)
    }

    @Test("Load threads for article")
    func loadThreadsForArticle() async throws {
        let thread = StoryThread.sampleThreads[0]
        mockService.fetchThreadsResult = .success([thread])

        sut.dispatch(action: .loadThreadsForArticle(articleID: "article-1"))
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(state.threads.count == 1)
        #expect(mockService.fetchThreadsCallCount == 1)
    }

    @Test("Follow thread updates state and logs analytics")
    func followThread() async throws {
        let thread = StoryThread.sampleThreads[0]
        mockService.followedThreadsResult = .success([thread])
        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .followThread(id: thread.id))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.followCallCount == 1)
        #expect(mockService.lastFollowedID == thread.id)
        let state = sut.currentState
        #expect(state.threads.first?.isFollowing == true)
    }

    @Test("Unfollow thread updates state and logs analytics")
    func unfollowThread() async throws {
        let thread = StoryThread.sampleThreads[0]
        mockService.followedThreadsResult = .success([thread])
        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .unfollowThread(id: thread.id))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.unfollowCallCount == 1)
        #expect(mockService.lastUnfollowedID == thread.id)
    }

    @Test("Generate summary updates thread summary")
    func generateSummary() async throws {
        let thread = StoryThread.sampleThreads[0]
        mockService.followedThreadsResult = .success([thread])
        mockService.generateSummaryResult = .success("New AI summary")
        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .generateSummary(threadID: thread.id))
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(state.generatingSummaryForID == nil)
        #expect(state.threads.first?.summary == "New AI summary")
        #expect(mockService.generateSummaryCallCount == 1)
    }

    @Test("Mark thread as read updates lastReadAt")
    func markAsRead() async throws {
        let thread = StoryThread.sampleThreads[0]
        mockService.followedThreadsResult = .success([thread])
        sut.dispatch(action: .loadFollowedThreads)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .markThreadAsRead(id: thread.id))
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(state.threads.first?.lastReadAt != nil)
        #expect(mockService.markAsReadCallCount == 1)
    }

    @Test("Refresh updates state correctly")
    func refresh() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)

        sut.dispatch(action: .refresh)
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(state.threads.count == 3)
    }
}
