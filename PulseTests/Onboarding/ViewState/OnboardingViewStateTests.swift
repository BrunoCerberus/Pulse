import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingViewState Tests")
struct OnboardingViewStateTests {
    @Test("Initial state has correct default values")
    func initialState() {
        let state = OnboardingViewState.initial

        #expect(state.currentPage == .welcome)
        #expect(state.isLastPage == false)
        #expect(state.isCompleted == false)
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = OnboardingViewState.initial
        let state2 = OnboardingViewState.initial

        #expect(state1 == state2)
    }

    @Test("States with different currentPage are not equal")
    func differentCurrentPage() {
        let state1 = OnboardingViewState.initial
        let state2 = OnboardingViewState(currentPage: .getStarted, isLastPage: false, isCompleted: false)

        #expect(state1 != state2)
    }

    @Test("States with different isLastPage are not equal")
    func differentIsLastPage() {
        let state1 = OnboardingViewState(currentPage: .getStarted, isLastPage: true, isCompleted: false)
        let state2 = OnboardingViewState(currentPage: .getStarted, isLastPage: false, isCompleted: false)

        #expect(state1 != state2)
    }

    @Test("States with different isCompleted are not equal")
    func differentIsCompleted() {
        let state1 = OnboardingViewState.initial
        let state2 = OnboardingViewState(currentPage: .welcome, isLastPage: false, isCompleted: true)

        #expect(state1 != state2)
    }
}
