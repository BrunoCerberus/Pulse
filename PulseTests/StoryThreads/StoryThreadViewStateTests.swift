import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadViewState Tests")
struct StoryThreadViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = StoryThreadViewState.initial

        #expect(state.threads.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(!state.showEmptyState)
        #expect(state.errorMessage == nil)
        #expect(state.generatingSummaryForID == nil)
    }

    @Test("StoryThreadViewState is Equatable")
    func equatable() {
        let state1 = StoryThreadViewState.initial
        let state2 = StoryThreadViewState.initial

        #expect(state1 == state2)
    }

    @Test("Modified state is not equal to initial")
    func modifiedNotEqual() {
        var state = StoryThreadViewState.initial
        state.isLoading = true

        #expect(state != StoryThreadViewState.initial)
    }

    @Test("State with showEmptyState is not equal to initial")
    func showEmptyStateNotEqual() {
        var state = StoryThreadViewState.initial
        state.showEmptyState = true

        #expect(state != StoryThreadViewState.initial)
    }

    @Test("State with errorMessage is not equal to initial")
    func errorMessageNotEqual() {
        var state = StoryThreadViewState.initial
        state.errorMessage = "Something went wrong"

        #expect(state != StoryThreadViewState.initial)
    }

    @Test("State with generatingSummaryForID is not equal to initial")
    func generatingSummaryNotEqual() {
        var state = StoryThreadViewState.initial
        state.generatingSummaryForID = StoryThread.sampleID1

        #expect(state != StoryThreadViewState.initial)
    }
}

@Suite("StoryThreadItem Tests")
struct StoryThreadItemTests {
    @Test("StoryThreadItem initializes from StoryThread")
    func initFromStoryThread() {
        let thread = StoryThread.sampleThreads[0]
        let item = StoryThreadItem(from: thread)

        #expect(item.id == thread.id)
        #expect(item.title == thread.title)
        #expect(item.articleCount == thread.articleIDs.count)
        #expect(item.summary == thread.summary)
        #expect(item.category == thread.category)
        #expect(item.isFollowing == thread.isFollowing)
    }

    @Test("StoryThreadItem articleCount matches articleIDs count")
    func articleCountMatchesIDs() {
        let thread = StoryThread.sampleThreads[0]
        let item = StoryThreadItem(from: thread)

        #expect(item.articleCount == 5)
    }

    @Test("StoryThreadItem lastUpdated is non-empty")
    func lastUpdatedIsNonEmpty() {
        let thread = StoryThread.sampleThreads[0]
        let item = StoryThreadItem(from: thread)

        #expect(!item.lastUpdated.isEmpty)
    }

    @Test("StoryThreadItem is Equatable")
    func equatable() {
        let thread = StoryThread.sampleThreads[0]
        let item1 = StoryThreadItem(from: thread)
        let item2 = StoryThreadItem(from: thread)

        #expect(item1 == item2)
    }

    @Test("Different StoryThreadItems are not equal")
    func differentItemsNotEqual() {
        let item1 = StoryThreadItem(from: StoryThread.sampleThreads[0])
        let item2 = StoryThreadItem(from: StoryThread.sampleThreads[1])

        #expect(item1 != item2)
    }
}
