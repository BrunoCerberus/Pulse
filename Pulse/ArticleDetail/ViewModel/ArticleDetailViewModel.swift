import Combine
import EntropyCore
import Foundation

@MainActor
final class ArticleDetailViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ArticleDetailViewState
    typealias ViewEvent = ArticleDetailViewEvent

    @Published private(set) var viewState: ArticleDetailViewState

    private let interactor: ArticleDetailDomainInteractor
    private let eventActionMap: ArticleDetailEventActionMap
    private let viewStateReducer: ArticleDetailViewStateReducer
    private var cancellables = Set<AnyCancellable>()

    init(
        article: Article,
        serviceLocator: ServiceLocator,
        eventActionMap: ArticleDetailEventActionMap = ArticleDetailEventActionMap(),
        viewStateReducer: ArticleDetailViewStateReducer = ArticleDetailViewStateReducer()
    ) {
        self.eventActionMap = eventActionMap
        self.viewStateReducer = viewStateReducer
        interactor = ArticleDetailDomainInteractor(article: article, serviceLocator: serviceLocator)
        viewState = .initial(article: article)

        setupBindings()
    }

    func handle(event: ArticleDetailViewEvent) {
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
