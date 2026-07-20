import EntropyCore
import Foundation

struct OnboardingEventActionMap: DomainEventActionMap {
    func map(event: OnboardingViewEvent) -> OnboardingDomainAction? {
        switch event {
        case .onNextTapped:
            .nextPage
        case .onSkipTapped:
            .skip
        case let .onPageChanged(page):
            .goToPage(page)
        case let .onToggleTopic(category):
            .toggleTopic(category)
        }
    }
}
