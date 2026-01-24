import Combine
import EntropyCore
import Foundation

/// ViewModel for the Home screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Handles view events by mapping them to domain actions via `HomeEventActionMap`.
///
/// ## Usage
/// ```swift
/// let viewModel = HomeViewModel(serviceLocator: serviceLocator)
/// viewModel.handle(event: .onAppear) // Triggers initial data load
/// ```
///
/// ## State Flow
/// `HomeDomainState` → `HomeViewStateReducer` → `HomeViewState`
@MainActor
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
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
