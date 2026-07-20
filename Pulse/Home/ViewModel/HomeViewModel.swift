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

    /// Raw `Article` pool surfaced separately from `viewState` so the
    /// embedded For You carousel can score against the actual articles
    /// (not their `ArticleViewItem` projections).
    @Published private(set) var articlePool: [Article] = []

    private let interactor: HomeDomainInteractor
    private let reducer: HomeViewStateReducer
    private let eventMap: HomeEventActionMap

    init(
        serviceLocator: ServiceLocator,
        reducer: HomeViewStateReducer = HomeViewStateReducer(),
        eventMap: HomeEventActionMap = HomeEventActionMap(),
    ) {
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

        // Mirror the raw articles so consumers (For You carousel) don't
        // have to round-trip through `ArticleViewItem`. Includes both
        // headlines *and* breaking news (deduped by ID) so a top-of-feed
        // breaking article that perfectly matches the user's interests can
        // also surface in For You — otherwise breaking-only articles never
        // get a chance to be re-ranked.
        interactor.statePublisher
            .map { state -> [Article] in
                var seen = Set<String>()
                var combined: [Article] = []
                combined.reserveCapacity(state.headlines.count + state.breakingNews.count)
                for article in state.headlines + state.breakingNews where seen.insert(article.id).inserted {
                    combined.append(article)
                }
                return combined
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$articlePool)
    }
}
