import Combine
import EntropyCore
import Foundation

/// ViewModel for the Media screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Handles view events by mapping them to domain actions via `MediaEventActionMap`.
///
/// ## Usage
/// ```swift
/// let viewModel = MediaViewModel(serviceLocator: serviceLocator)
/// viewModel.handle(event: .onAppear) // Triggers initial data load
/// ```
///
/// ## State Flow
/// `MediaDomainState` → `MediaViewStateReducer` → `MediaViewState`
@MainActor
final class MediaViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = MediaViewState
    typealias ViewEvent = MediaViewEvent

    @Published private(set) var viewState: MediaViewState = .initial

    private let interactor: MediaDomainInteractor
    private let reducer: MediaViewStateReducer
    private let eventMap: MediaEventActionMap

    init(
        serviceLocator: ServiceLocator,
        reducer: MediaViewStateReducer = MediaViewStateReducer(),
        eventMap: MediaEventActionMap = MediaEventActionMap()
    ) {
        interactor = MediaDomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap

        setupBindings()
    }

    func handle(event: MediaViewEvent) {
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
