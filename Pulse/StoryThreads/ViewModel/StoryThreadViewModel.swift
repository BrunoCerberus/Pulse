import Combine
import EntropyCore
import Foundation

/// ViewModel bridging the Story Threads view with the domain interactor.
@MainActor
final class StoryThreadViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = StoryThreadViewState
    typealias ViewEvent = StoryThreadViewEvent

    @Published private(set) var viewState: StoryThreadViewState = .initial

    private let interactor: StoryThreadDomainInteractor
    private let reducer: StoryThreadViewStateReducer
    private let eventMap: StoryThreadEventActionMap

    init(
        serviceLocator: ServiceLocator,
        reducer: StoryThreadViewStateReducer = StoryThreadViewStateReducer(),
        eventMap: StoryThreadEventActionMap = StoryThreadEventActionMap()
    ) {
        interactor = StoryThreadDomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap
        setupBindings()
    }

    func handle(event: StoryThreadViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    /// Provides direct access to the interactor for detail views that need specific actions.
    func dispatch(action: StoryThreadDomainAction) {
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
