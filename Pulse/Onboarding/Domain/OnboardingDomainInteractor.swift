import Combine
import EntropyCore
import Foundation

@MainActor
final class OnboardingDomainInteractor: CombineInteractor {
    typealias DomainState = OnboardingDomainState
    typealias DomainAction = OnboardingDomainAction

    let stateSubject = CurrentValueSubject<OnboardingDomainState, Never>(.initial)
    var cancellables = Set<AnyCancellable>()

    private var onboardingService: OnboardingService
    private let analyticsService: AnalyticsService?

    var statePublisher: AnyPublisher<OnboardingDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: OnboardingDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        onboardingService = (try? serviceLocator.retrieve(OnboardingService.self)) ?? MockOnboardingService()
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
    }

    func dispatch(action: OnboardingDomainAction) {
        switch action {
        case .nextPage:
            handleNextPage()
        case let .goToPage(page):
            updateState { $0.currentPage = page }
        case .skip:
            handleSkip()
        case .complete:
            handleComplete()
        }
    }

    private func handleNextPage() {
        let pages = OnboardingPage.allCases
        let currentIndex = currentState.currentPage.rawValue

        if currentIndex < pages.count - 1 {
            updateState { $0.currentPage = pages[currentIndex + 1] }
        } else {
            handleComplete()
        }
    }

    private func handleSkip() {
        analyticsService?.logEvent(.onboardingSkipped(page: currentState.currentPage.rawValue))
        markCompleted()
    }

    private func handleComplete() {
        analyticsService?.logEvent(.onboardingCompleted(page: currentState.currentPage.rawValue))
        markCompleted()
    }

    private func markCompleted() {
        onboardingService.hasCompletedOnboarding = true
        updateState { $0.isCompleted = true }
    }

    private func updateState(_ transform: (inout OnboardingDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
