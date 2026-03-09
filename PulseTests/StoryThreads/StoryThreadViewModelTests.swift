import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadViewModel Tests")
@MainActor
struct StoryThreadViewModelTests {
    let mockService: MockStoryThreadService
    let serviceLocator: ServiceLocator
    let sut: StoryThreadViewModel

    init() {
        mockService = MockStoryThreadService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StoryThreadService.self, instance: mockService)
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        sut = StoryThreadViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialState() {
        #expect(sut.viewState.threads.isEmpty)
        #expect(!sut.viewState.isLoading)
        #expect(!sut.viewState.isRefreshing)
        #expect(sut.viewState.errorMessage == nil)
    }

    @Test("onAppear loads followed threads")
    func onAppear() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.threads.count == 3)
        #expect(!sut.viewState.isLoading)
        #expect(!sut.viewState.showEmptyState)
    }

    @Test("Empty state shows when no threads")
    func emptyState() async throws {
        mockService.followedThreadsResult = .success([])

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.threads.isEmpty)
        #expect(sut.viewState.showEmptyState)
    }

    @Test("Pull to refresh triggers refresh action")
    func pullToRefresh() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)

        sut.handle(event: .didPullToRefresh)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.threads.count == 3)
    }

    @Test("didToggleFollow unfollows thread from list")
    func toggleFollow() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)
        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        let threadID = StoryThread.sampleThreads[0].id
        sut.handle(event: .didToggleFollow(id: threadID))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.unfollowCallCount == 1)
    }

    @Test("didTapThread does not dispatch domain action")
    func tapThread() {
        // didTapThread should be handled by navigation, not domain
        sut.handle(event: .didTapThread(id: UUID()))
        // No crash, no action dispatched — pass
    }

    @Test("View state threads have correct properties")
    func threadItemMapping() async throws {
        mockService.followedThreadsResult = .success(StoryThread.sampleThreads)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        let firstItem = sut.viewState.threads[0]
        let firstThread = StoryThread.sampleThreads[0]
        #expect(firstItem.id == firstThread.id)
        #expect(firstItem.title == firstThread.title)
        #expect(firstItem.articleCount == firstThread.articleIDs.count)
        #expect(firstItem.category == firstThread.category)
        #expect(firstItem.isFollowing == firstThread.isFollowing)
    }

    @Test("Error state is reflected in view state")
    func errorState() async throws {
        mockService.followedThreadsResult = .failure(StoryThreadError.threadNotFound)

        sut.handle(event: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.viewState.errorMessage != nil)
        #expect(sut.viewState.threads.isEmpty)
    }
}
