import Combine
import EntropyCore
import Foundation

@MainActor
final class OnboardingViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = OnboardingViewState
    typealias ViewEvent = OnboardingViewEvent

    @Published private(set) var viewState: OnboardingViewState = .initial

    private let interactor: OnboardingDomainInteractor
    private let reducer: OnboardingViewStateReducer
    private let eventMap: OnboardingEventActionMap

    init(
        serviceLocator: ServiceLocator,
        reducer: OnboardingViewStateReducer = OnboardingViewStateReducer(),
        eventMap: OnboardingEventActionMap = OnboardingEventActionMap()
    ) {
        interactor = OnboardingDomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap

        setupBindings()
    }

    func handle(event: OnboardingViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] state in reducer.reduce(domainState: state) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
