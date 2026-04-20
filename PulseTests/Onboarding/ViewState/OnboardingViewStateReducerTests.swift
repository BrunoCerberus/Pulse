import Foundation
@testable import Pulse
import Testing

@Suite("OnboardingViewStateReducer Tests")
struct OnboardingViewStateReducerTests {
    let sut = OnboardingViewStateReducer()

    @Test("Reduces initial state correctly")
    func reduceInitialState() {
        let domainState = OnboardingDomainState.initial
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentPage == .welcome)
        #expect(viewState.isLastPage == false)
        #expect(viewState.selectedTopics.isEmpty)
        #expect(viewState.isCompleted == false)
    }

    @Test("isLastPage is true when on getStarted")
    func reduceLastPage() {
        let domainState = OnboardingDomainState(
            currentPage: .getStarted,
            selectedTopics: [],
            isCompleted: false
        )
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLastPage == true)
    }

    @Test("isLastPage is false for middle pages")
    func reduceMiddlePage() {
        let domainState = OnboardingDomainState(
            currentPage: .aiPowered,
            selectedTopics: [],
            isCompleted: false
        )
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLastPage == false)
    }

    @Test("isLastPage is false on chooseTopics page")
    func reduceChooseTopicsPage() {
        let domainState = OnboardingDomainState(
            currentPage: .chooseTopics,
            selectedTopics: [],
            isCompleted: false
        )
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLastPage == false)
    }

    @Test("Reduces selectedTopics")
    func reduceSelectedTopics() {
        let domainState = OnboardingDomainState(
            currentPage: .chooseTopics,
            selectedTopics: [.technology, .science],
            isCompleted: false
        )
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedTopics == [.technology, .science])
    }

    @Test("Reduces completed state")
    func reduceCompleted() {
        let domainState = OnboardingDomainState(
            currentPage: .getStarted,
            selectedTopics: [],
            isCompleted: true
        )
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isCompleted == true)
    }
}
