import Combine
import EntropyCore
import Foundation

/// ViewModel for the Article Summarization sheet.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Handles view events by mapping them to domain actions via `SummarizationEventActionMap`.
///
/// The summarization feature uses on-device LLM to generate article summaries
/// with streaming text output and progress tracking.
///
/// ## State Flow
/// `SummarizationDomainState` → `SummarizationViewStateReducer` → `SummarizationViewState`
///
/// - Note: This is a **Premium** feature.
@MainActor
final class SummarizationViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SummarizationViewState
    typealias ViewEvent = SummarizationViewEvent

    @Published private(set) var viewState: SummarizationViewState

    private let interactor: SummarizationDomainInteractor
    private let eventActionMap: SummarizationEventActionMap
    private let viewStateReducer: SummarizationViewStateReducer

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
