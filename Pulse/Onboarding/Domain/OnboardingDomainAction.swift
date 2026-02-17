import Foundation

enum OnboardingDomainAction: Equatable {
    case nextPage
    case goToPage(OnboardingPage)
    case skip
    case complete
}
