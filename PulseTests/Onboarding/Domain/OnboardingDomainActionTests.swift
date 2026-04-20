import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingDomainAction Tests")
struct OnboardingDomainActionTests {
    @Test("nextPage action exists")
    func nextPage() {
        let action = OnboardingDomainAction.nextPage
        #expect(action == .nextPage)
    }

    @Test("skip action exists")
    func skip() {
        let action = OnboardingDomainAction.skip
        #expect(action == .skip)
    }

    @Test("complete action exists")
    func complete() {
        let action = OnboardingDomainAction.complete
        #expect(action == .complete)
    }

    @Test("goToPage action exists")
    func goToPage() {
        let action = OnboardingDomainAction.goToPage(.aiPowered)
        #expect(action == .goToPage(.aiPowered))
    }

    @Test("toggleTopic action exists")
    func toggleTopic() {
        let action = OnboardingDomainAction.toggleTopic(.technology)
        #expect(action == .toggleTopic(.technology))
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(OnboardingDomainAction.nextPage == OnboardingDomainAction.nextPage)
        #expect(OnboardingDomainAction.skip == OnboardingDomainAction.skip)
        #expect(OnboardingDomainAction.complete == OnboardingDomainAction.complete)
        #expect(OnboardingDomainAction.goToPage(.welcome) == OnboardingDomainAction.goToPage(.welcome))
        #expect(OnboardingDomainAction.toggleTopic(.science) == OnboardingDomainAction.toggleTopic(.science))
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(OnboardingDomainAction.nextPage != OnboardingDomainAction.skip)
        #expect(OnboardingDomainAction.skip != OnboardingDomainAction.complete)
        #expect(OnboardingDomainAction.nextPage != OnboardingDomainAction.goToPage(.welcome))
        #expect(OnboardingDomainAction.toggleTopic(.technology) != OnboardingDomainAction.toggleTopic(.science))
    }

    @Test("goToPage with different pages are not equal")
    func goToPageDifferentPages() {
        #expect(OnboardingDomainAction.goToPage(.welcome) != OnboardingDomainAction.goToPage(.getStarted))
        #expect(OnboardingDomainAction.goToPage(.aiPowered) != OnboardingDomainAction.goToPage(.stayConnected))
        #expect(OnboardingDomainAction.goToPage(.chooseTopics) != OnboardingDomainAction.goToPage(.getStarted))
    }
}
