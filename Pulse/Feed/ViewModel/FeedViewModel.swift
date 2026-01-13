import Combine
import EntropyCore
import Foundation

@MainActor
final class FeedViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = FeedViewState
    typealias ViewEvent = FeedViewEvent

    @Published private(set) var viewState: FeedViewState = .initial

    private let interactor: FeedDomainInteractor
    private let eventActionMap: FeedEventActionMap
    private let viewStateReducer: FeedViewStateReducer
    private var cancellables = Set<AnyCancellable>()

    init(
        serviceLocator: ServiceLocator,
        eventActionMap: FeedEventActionMap = FeedEventActionMap(),
        viewStateReducer: FeedViewStateReducer = FeedViewStateReducer()
    ) {
        self.eventActionMap = eventActionMap
        self.viewStateReducer = viewStateReducer
        interactor = FeedDomainInteractor(serviceLocator: serviceLocator)

        setupBindings()
    }

    func handle(event: FeedViewEvent) {
        guard let action = eventActionMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [viewStateReducer] state in
                viewStateReducer.reduce(domainState: state)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
