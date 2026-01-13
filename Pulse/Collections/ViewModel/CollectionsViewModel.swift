import Combine
import EntropyCore
import Foundation

@MainActor
final class CollectionsViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = CollectionsViewState
    typealias ViewEvent = CollectionsViewEvent

    @Published private(set) var viewState: CollectionsViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: CollectionsDomainInteractor
    private let reducer: CollectionsViewStateReducer
    private let eventMap: CollectionsEventActionMap
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        reducer: CollectionsViewStateReducer = CollectionsViewStateReducer(),
        eventMap: CollectionsEventActionMap = CollectionsEventActionMap()
    ) {
        self.serviceLocator = serviceLocator
        interactor = CollectionsDomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap

        setupBindings()
    }

    func handle(event: CollectionsViewEvent) {
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
