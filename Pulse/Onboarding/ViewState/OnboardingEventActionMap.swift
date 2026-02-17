import EntropyCore
import Foundation

struct OnboardingEventActionMap: DomainEventActionMap {
    func map(event: OnboardingViewEvent) -> OnboardingDomainAction? {
        switch event {
        case .onNextTapped:
            return .nextPage
        case .onSkipTapped:
            return .skip
        case let .onPageChanged(page):
            return .goToPage(page)
        }
    }
}
