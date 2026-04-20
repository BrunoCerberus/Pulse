import Foundation

enum OnboardingDomainAction: Equatable {
    case nextPage
    case goToPage(OnboardingPage)
    case toggleTopic(NewsCategory)
    case skip
    case complete
}
