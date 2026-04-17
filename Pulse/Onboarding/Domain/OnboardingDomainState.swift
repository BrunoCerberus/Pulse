import Foundation

struct OnboardingDomainState: Equatable {
    var currentPage: OnboardingPage
    var selectedTopics: Set<NewsCategory>
    var isCompleted: Bool

    static var initial: OnboardingDomainState {
        OnboardingDomainState(
            currentPage: .welcome,
            selectedTopics: [],
            isCompleted: false
        )
    }
}
