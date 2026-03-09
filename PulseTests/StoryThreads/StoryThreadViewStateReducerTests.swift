import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadViewStateReducer Tests")
@MainActor
struct StoryThreadViewStateReducerTests {
    let sut = StoryThreadViewStateReducer()

    @Test("Reduces initial state correctly")
    func reduceInitialState() {
        let domainState = StoryThreadDomainState.initial
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.threads.isEmpty)
        #expect(!viewState.isLoading)
        #expect(!viewState.isRefreshing)
        #expect(viewState.showEmptyState) // Empty state shown: not loading, no threads
        #expect(viewState.errorMessage == nil)
        #expect(viewState.generatingSummaryForID == nil)
    }

    @Test("Loading state reduces correctly")
    func reduceLoadingState() {
        var domainState = StoryThreadDomainState.initial
        domainState.isLoading = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoading)
        #expect(!viewState.showEmptyState) // Don't show empty while loading
    }

    @Test("Empty state shows when not loading and no threads")
    func reduceEmptyState() {
        var domainState = StoryThreadDomainState.initial
        domainState.isLoading = false
        domainState.threads = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState)
    }

    @Test("Loaded threads reduce to view items")
    func reduceLoadedState() {
        var domainState = StoryThreadDomainState.initial
        domainState.threads = StoryThread.sampleThreads

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.threads.count == 3)
        #expect(viewState.threads[0].title == "Ukraine Peace Negotiations")
        #expect(viewState.threads[0].articleCount == 5)
        #expect(viewState.threads[0].category == "world")
        #expect(viewState.threads[0].isFollowing)
        #expect(!viewState.showEmptyState)
    }

    @Test("Error state reduces correctly")
    func reduceErrorState() {
        var domainState = StoryThreadDomainState.initial
        domainState.error = "Network error"

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == "Network error")
    }

    @Test("Refreshing state reduces correctly")
    func reduceRefreshingState() {
        var domainState = StoryThreadDomainState.initial
        domainState.isRefreshing = true
        domainState.threads = StoryThread.sampleThreads

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isRefreshing)
        #expect(!viewState.showEmptyState) // Don't show empty while refreshing
        #expect(viewState.threads.count == 3)
    }

    @Test("Generating summary ID passes through")
    func reduceGeneratingSummary() {
        var domainState = StoryThreadDomainState.initial
        let threadID = StoryThread.sampleThreads[0].id
        domainState.generatingSummaryForID = threadID

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.generatingSummaryForID == threadID)
    }

    @Test("Unread count is reflected in view items")
    func reduceUnreadCount() {
        var domainState = StoryThreadDomainState.initial
        // Thread with no lastReadAt should show unread count = articleIDs.count
        let thread = StoryThread(
            title: "Test",
            summary: "Test summary",
            articleIDs: ["1", "2", "3"],
            category: "world"
        )
        domainState.threads = [thread]

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.threads[0].unreadCount == 3)
    }
}
