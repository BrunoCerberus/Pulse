import Foundation

struct OnboardingViewState: Equatable {
    var currentPage: OnboardingPage
    var isLastPage: Bool
    var isCompleted: Bool

    static var initial: OnboardingViewState {
        OnboardingViewState(
            currentPage: .welcome,
            isLastPage: false,
            isCompleted: false
        )
    }
}
