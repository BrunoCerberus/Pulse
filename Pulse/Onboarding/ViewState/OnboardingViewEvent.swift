import Foundation

enum OnboardingViewEvent: Equatable {
    case onNextTapped
    case onSkipTapped
    case onPageChanged(OnboardingPage)
}
