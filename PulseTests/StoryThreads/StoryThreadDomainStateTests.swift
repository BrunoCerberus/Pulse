import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadDomainState Tests")
struct StoryThreadDomainStateTests {
    private let testID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Initial State Tests

    @Test("Initial state has correct default values")
    func initialState() {
        let state = StoryThreadDomainState.initial

        #expect(state.threads.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.isRefreshing == false)
        #expect(state.error == nil)
        #expect(state.selectedThreadID == nil)
        #expect(state.generatingSummaryForID == nil)
    }

    // MARK: - State Properties Tests

    @Test("threads can be set")
    func threadsCanBeSet() {
        var state = StoryThreadDomainState.initial
        state.threads = StoryThread.sampleThreads

        #expect(state.threads.count == 3)
        #expect(state.threads[0].id == StoryThread.sampleID1)
        #expect(state.threads[1].id == StoryThread.sampleID2)
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = StoryThreadDomainState.initial
        #expect(state.isLoading == false)

        state.isLoading = true
        #expect(state.isLoading == true)
    }

    @Test("isRefreshing can be set")
    func isRefreshingCanBeSet() {
        var state = StoryThreadDomainState.initial
        #expect(state.isRefreshing == false)

        state.isRefreshing = true
        #expect(state.isRefreshing == true)
    }

    @Test("error can be set")
    func errorCanBeSet() {
        var state = StoryThreadDomainState.initial
        #expect(state.error == nil)

        state.error = "Network error"
        #expect(state.error == "Network error")
    }

    @Test("selectedThreadID can be set")
    func selectedThreadIDCanBeSet() {
        var state = StoryThreadDomainState.initial
        #expect(state.selectedThreadID == nil)

        state.selectedThreadID = testID
        #expect(state.selectedThreadID == testID)
    }

    @Test("selectedThreadID can be cleared")
    func selectedThreadIDCanBeCleared() {
        var state = StoryThreadDomainState.initial
        state.selectedThreadID = testID
        #expect(state.selectedThreadID != nil)

        state.selectedThreadID = nil
        #expect(state.selectedThreadID == nil)
    }

    @Test("generatingSummaryForID can be set")
    func generatingSummaryForIDCanBeSet() {
        var state = StoryThreadDomainState.initial
        #expect(state.generatingSummaryForID == nil)

        state.generatingSummaryForID = testID
        #expect(state.generatingSummaryForID == testID)
    }

    // MARK: - Equatable Tests

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = StoryThreadDomainState.initial
        let state2 = StoryThreadDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different threads are not equal")
    func statesWithDifferentThreads() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.threads = StoryThread.sampleThreads

        #expect(state1 != state2)
    }

    @Test("States with different isLoading are not equal")
    func statesWithDifferentIsLoading() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.isLoading = true

        #expect(state1 != state2)
    }

    @Test("States with different isRefreshing are not equal")
    func statesWithDifferentIsRefreshing() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.isRefreshing = true

        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func statesWithDifferentErrors() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.error = "Error message"

        #expect(state1 != state2)
    }

    @Test("States with different selectedThreadID are not equal")
    func statesWithDifferentSelectedThreadID() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.selectedThreadID = testID

        #expect(state1 != state2)
    }

    @Test("States with different generatingSummaryForID are not equal")
    func statesWithDifferentGeneratingSummaryForID() {
        let state1 = StoryThreadDomainState.initial
        var state2 = StoryThreadDomainState.initial
        state2.generatingSummaryForID = testID

        #expect(state1 != state2)
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = StoryThreadDomainState.initial
        state1.isLoading = true
        state1.error = "Test error"
        state1.selectedThreadID = testID

        var state2 = StoryThreadDomainState.initial
        state2.isLoading = true
        state2.error = "Test error"
        state2.selectedThreadID = testID

        #expect(state1 == state2)
    }
}
