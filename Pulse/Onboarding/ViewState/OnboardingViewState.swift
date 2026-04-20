import Foundation

struct OnboardingViewState: Equatable {
    var currentPage: OnboardingPage
    var isLastPage: Bool
    var selectedTopics: Set<NewsCategory>
    var isCompleted: Bool

    static var initial: OnboardingViewState {
        OnboardingViewState(
            currentPage: .welcome,
            isLastPage: false,
            selectedTopics: [],
            isCompleted: false
        )
    }
}
