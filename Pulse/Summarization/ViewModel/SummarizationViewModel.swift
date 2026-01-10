import Combine
import Foundation

@MainActor
final class SummarizationViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SummarizationViewState
    typealias ViewEvent = SummarizationViewEvent

    @Published private(set) var viewState: SummarizationViewState

    private let interactor: SummarizationDomainInteractor
    private let eventActionMap: SummarizationEventActionMap
    private let viewStateReducer: SummarizationViewStateReducer
    private var cancellables = Set<AnyCancellable>()

    init(
        article: Article,
        serviceLocator: ServiceLocator,
        eventActionMap: SummarizationEventActionMap = SummarizationEventActionMap(),
        viewStateReducer: SummarizationViewStateReducer = SummarizationViewStateReducer()
    ) {
        self.eventActionMap = eventActionMap
        self.viewStateReducer = viewStateReducer
        interactor = SummarizationDomainInteractor(article: article, serviceLocator: serviceLocator)
        viewState = .initial(article: article)

        setupBindings()
    }

    func handle(event: SummarizationViewEvent) {
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
