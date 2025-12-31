import Combine
import Foundation

final class HomeViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = HomeViewState
    typealias ViewEvent = HomeViewEvent

    @Published private(set) var viewState: HomeViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: HomeDomainInteractor
    private let reducer: HomeViewStateReducer
    private let eventMap: HomeEventActionMap
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        reducer: HomeViewStateReducer = HomeViewStateReducer(),
        eventMap: HomeEventActionMap = HomeEventActionMap()
    ) {
        self.serviceLocator = serviceLocator
        interactor = HomeDomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap

        setupBindings()
    }

    func handle(event: HomeViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] state in reducer.reduce(domainState: state) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
