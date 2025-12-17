import Foundation
import Combine

final class HomeViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = HomeViewState
    typealias ViewEvent = HomeViewEvent

    @Published private(set) var viewState: HomeViewState = .initial
    @Published var selectedArticle: Article?
    @Published var shareArticle: Article?

    private let interactor: HomeDomainInteractor
    private let reducer: HomeViewStateReducer
    private let eventMap: HomeEventActionMap
    private var cancellables = Set<AnyCancellable>()

    init(
        interactor: HomeDomainInteractor = HomeDomainInteractor(),
        reducer: HomeViewStateReducer = HomeViewStateReducer(),
        eventMap: HomeEventActionMap = HomeEventActionMap()
    ) {
        self.interactor = interactor
        self.reducer = reducer
        self.eventMap = eventMap

        setupBindings()
    }

    func handle(event: HomeViewEvent) {
        if case let .onArticleTapped(article) = event {
            selectedArticle = article
        }
        if case let .onShareTapped(article) = event {
            shareArticle = article
        }

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
