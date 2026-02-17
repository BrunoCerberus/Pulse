import Foundation

struct OnboardingDomainState: Equatable {
    var currentPage: OnboardingPage
    var isCompleted: Bool

    static var initial: OnboardingDomainState {
        OnboardingDomainState(
            currentPage: .welcome,
            isCompleted: false
        )
    }
}
