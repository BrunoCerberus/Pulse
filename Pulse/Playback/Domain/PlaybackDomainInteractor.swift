import Combine
import EntropyCore
import Foundation

/// Domain interactor for the global playback player (mini player + queue sheet).
///
/// Thin coordinator over `PlaybackQueueService`: transport actions delegate to
/// the service, and the service's state stream is mirrored into domain state.
/// Deliberately has **no** teardown on deinit — playback must survive any
/// view's lifecycle; `PlaybackQueueService.stop()` is the only way audio ends.
///
/// ## Data Flow
/// 1. Views dispatch `PlaybackDomainAction` via `dispatch(action:)`
/// 2. Interactor delegates to `PlaybackQueueService` and updates `PlaybackDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `PlaybackQueueService`: The global playback queue
@MainActor
final class PlaybackDomainInteractor: CombineInteractor {
    typealias DomainState = PlaybackDomainState
    typealias DomainAction = PlaybackDomainAction

    private let playbackQueueService: PlaybackQueueService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        playbackQueueService = try? serviceLocator.retrieve(PlaybackQueueService.self)
        if playbackQueueService == nil {
            Logger.shared.service("PlaybackQueueService not registered; mini player inert", level: .warning)
        }

        setupBindings()
    }

    func dispatch(action: DomainAction) {
        switch action {
        case let .queueStateChanged(queueState):
            updateState { state in
                state.queueState = queueState
                // The sheet has no reason to outlive the queue.
                if queueState.currentIndex == nil {
                    state.isQueueSheetPresented = false
                }
            }
        case .togglePlayPause:
            playbackQueueService?.togglePlayPause()
        case .next:
            playbackQueueService?.next()
        case .previous:
            playbackQueueService?.previous()
        case let .skipTo(itemID):
            playbackQueueService?.skip(to: itemID)
        case .cycleSpeed:
            playbackQueueService?.cycleSpeed()
        case .stop:
            playbackQueueService?.stop()
        case .showQueueSheet:
            updateState { $0.isQueueSheetPresented = true }
        case .dismissQueueSheet:
            updateState { $0.isQueueSheetPresented = false }
        }
    }

    private func setupBindings() {
        playbackQueueService?.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] queueState in
                self?.dispatch(action: .queueStateChanged(queueState))
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
