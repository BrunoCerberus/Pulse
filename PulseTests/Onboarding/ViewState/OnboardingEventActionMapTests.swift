import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingEventActionMap Tests")
struct OnboardingEventActionMapTests {
    let sut = OnboardingEventActionMap()

    @Test("onNextTapped maps to nextPage")
    func mapNextTapped() {
        let action = sut.map(event: .onNextTapped)
        #expect(action == .nextPage)
    }

    @Test("onSkipTapped maps to skip")
    func mapSkipTapped() {
        let action = sut.map(event: .onSkipTapped)
        #expect(action == .skip)
    }

    @Test("onPageChanged maps to goToPage")
    func mapPageChanged() {
        let action = sut.map(event: .onPageChanged(.stayConnected))
        #expect(action == .goToPage(.stayConnected))
    }
}
