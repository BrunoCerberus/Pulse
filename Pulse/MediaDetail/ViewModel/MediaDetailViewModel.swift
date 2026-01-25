import Combine
import EntropyCore
import Foundation

/// ViewModel for the Media Detail screen.
///
/// Implements `CombineViewModel` to transform domain state into view state.
/// Handles view events by mapping them to domain actions via `MediaDetailEventActionMap`.
///
/// ## Features
/// - Video playback via WKWebView (YouTube embeds)
/// - Podcast playback via AVPlayer with custom controls
/// - Bookmark toggle with optimistic updates
/// - Share sheet integration
///
/// ## State Flow
/// `MediaDetailDomainState` -> `MediaDetailViewStateReducer` -> `MediaDetailViewState`
@MainActor
final class MediaDetailViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = MediaDetailViewState
    typealias ViewEvent = MediaDetailViewEvent

    @Published private(set) var viewState: MediaDetailViewState

    private let interactor: MediaDetailDomainInteractor
    private let eventActionMap: MediaDetailEventActionMap
    private let viewStateReducer: MediaDetailViewStateReducer
    private var cancellables = Set<AnyCancellable>()

    init(
        article: Article,
        serviceLocator: ServiceLocator,
        eventActionMap: MediaDetailEventActionMap = MediaDetailEventActionMap(),
        viewStateReducer: MediaDetailViewStateReducer = MediaDetailViewStateReducer()
    ) {
        self.eventActionMap = eventActionMap
        self.viewStateReducer = viewStateReducer
        interactor = MediaDetailDomainInteractor(article: article, serviceLocator: serviceLocator)
        viewState = .initial(article: article)

        setupBindings()
    }

    func handle(event: MediaDetailViewEvent) {
        // Handle play/pause toggle specially since it depends on current state
        if case .onPlayPauseTapped = event {
            if viewState.isPlaying {
                interactor.dispatch(action: .pause)
            } else {
                interactor.dispatch(action: .play)
            }
            return
        }

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
