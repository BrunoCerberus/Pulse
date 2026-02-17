import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingDomainState Tests")
struct OnboardingDomainStateTests {
    @Test("Initial state has correct default values")
    func initialState() {
        let state = OnboardingDomainState.initial

        #expect(state.currentPage == .welcome)
        #expect(state.isCompleted == false)
    }

    @Test("State properties can be mutated")
    func statePropertiesMutability() {
        var state = OnboardingDomainState.initial

        state.currentPage = .aiPowered
        #expect(state.currentPage == .aiPowered)

        state.currentPage = .stayConnected
        #expect(state.currentPage == .stayConnected)

        state.currentPage = .getStarted
        #expect(state.currentPage == .getStarted)

        state.isCompleted = true
        #expect(state.isCompleted == true)
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = OnboardingDomainState.initial
        let state2 = OnboardingDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different currentPage are not equal")
    func differentCurrentPage() {
        let state1 = OnboardingDomainState.initial
        var state2 = OnboardingDomainState.initial
        state2.currentPage = .getStarted

        #expect(state1 != state2)
    }

    @Test("States with different isCompleted are not equal")
    func differentIsCompleted() {
        let state1 = OnboardingDomainState.initial
        var state2 = OnboardingDomainState.initial
        state2.isCompleted = true

        #expect(state1 != state2)
    }
}
