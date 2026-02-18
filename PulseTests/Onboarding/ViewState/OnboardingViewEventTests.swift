import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingViewEvent Tests")
struct OnboardingViewEventTests {
    @Test("onNextTapped event exists")
    func onNextTapped() {
        #expect(OnboardingViewEvent.onNextTapped == .onNextTapped)
    }

    @Test("onSkipTapped event exists")
    func onSkipTapped() {
        #expect(OnboardingViewEvent.onSkipTapped == .onSkipTapped)
    }

    @Test("onPageChanged event exists")
    func onPageChanged() {
        let event = OnboardingViewEvent.onPageChanged(.aiPowered)
        #expect(event == .onPageChanged(.aiPowered))
    }

    @Test("Same events are equal")
    func sameEventsAreEqual() {
        #expect(OnboardingViewEvent.onNextTapped == OnboardingViewEvent.onNextTapped)
        #expect(OnboardingViewEvent.onSkipTapped == OnboardingViewEvent.onSkipTapped)
        #expect(OnboardingViewEvent.onPageChanged(.welcome) == OnboardingViewEvent.onPageChanged(.welcome))
    }

    @Test("Different events are not equal")
    func differentEventsAreNotEqual() {
        #expect(OnboardingViewEvent.onNextTapped != OnboardingViewEvent.onSkipTapped)
        #expect(OnboardingViewEvent.onNextTapped != OnboardingViewEvent.onPageChanged(.welcome))
    }

    @Test("onPageChanged with different pages are not equal")
    func onPageChangedDifferentPages() {
        #expect(OnboardingViewEvent.onPageChanged(.welcome) != OnboardingViewEvent.onPageChanged(.getStarted))
        #expect(OnboardingViewEvent.onPageChanged(.aiPowered) != OnboardingViewEvent.onPageChanged(.stayConnected))
    }
}
