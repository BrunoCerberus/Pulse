import EntropyCore
import Foundation

struct OnboardingViewStateReducer: ViewStateReducing {
    func reduce(domainState: OnboardingDomainState) -> OnboardingViewState {
        OnboardingViewState(
            currentPage: domainState.currentPage,
            isLastPage: domainState.currentPage == OnboardingPage.allCases.last,
            selectedTopics: domainState.selectedTopics,
            isCompleted: domainState.isCompleted
        )
    }
}
