import Combine
import EntropyCore
import Foundation

/// ViewModel for the global mini player and queue sheet.
///
/// Implements `CombineViewModel` to transform playback domain state into view
/// state. Lives on the `Coordinator` for the app's lifetime so the mini player
/// can render above every screen.
@MainActor
final class PlaybackViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = PlaybackViewState
    typealias ViewEvent = PlaybackViewEvent

    @Published private(set) var viewState: PlaybackViewState = .initial

    private let interactor: PlaybackDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = PlaybackDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: PlaybackViewEvent) {
        switch event {
        case .onPlayPauseTapped:
            interactor.dispatch(action: .togglePlayPause)
        case .onNextTapped:
            interactor.dispatch(action: .next)
        case .onPreviousTapped:
            interactor.dispatch(action: .previous)
        case .onStopTapped:
            interactor.dispatch(action: .stop)
        case .onSpeedTapped:
            interactor.dispatch(action: .cycleSpeed)
        case .onExpandTapped:
            interactor.dispatch(action: .showQueueSheet)
        case .onQueueSheetDismissed:
            interactor.dispatch(action: .dismissQueueSheet)
        case let .onQueueItemTapped(itemID):
            interactor.dispatch(action: .skipTo(itemID: itemID))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                let queue = state.queueState
                return PlaybackViewState(
                    isVisible: queue.currentIndex != nil,
                    title: queue.currentItem?.title ?? "",
                    sourceName: queue.currentItem?.sourceName ?? "",
                    isPlaying: queue.playbackState == .playing,
                    itemProgress: queue.itemProgress,
                    speedLabel: queue.speedPreset.label,
                    hasNext: queue.hasNext,
                    hasPrevious: queue.hasPrevious,
                    queuePositionLabel: queue.queuePositionLabel,
                    isQueueSheetPresented: state.isQueueSheetPresented,
                    queueItems: queue.items.enumerated().map { index, item in
                        PlaybackQueueItemViewItem(
                            id: item.id,
                            title: item.title,
                            sourceName: item.sourceName,
                            isCurrent: index == queue.currentIndex,
                            isDigest: item.kind == .digest
                        )
                    }
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

/// View state for the mini player and queue sheet.
struct PlaybackViewState: Equatable {
    /// Whether the mini player should be shown at all.
    var isVisible: Bool

    /// Title of the item currently being narrated.
    var title: String

    /// Source name of the current item.
    var sourceName: String

    var isPlaying: Bool

    /// Progress (0...1) through the current item.
    var itemProgress: Double

    /// Current speed preset label (e.g. "1.25x").
    var speedLabel: String

    var hasNext: Bool

    var hasPrevious: Bool

    /// Queue position (e.g. "2/11"); `nil` for single-article playback.
    var queuePositionLabel: String?

    var isQueueSheetPresented: Bool

    var queueItems: [PlaybackQueueItemViewItem]

    static let initial = PlaybackViewState(
        isVisible: false,
        title: "",
        sourceName: "",
        isPlaying: false,
        itemProgress: 0.0,
        speedLabel: TTSSpeedPreset.normal.label,
        hasNext: false,
        hasPrevious: false,
        queuePositionLabel: nil,
        isQueueSheetPresented: false,
        queueItems: []
    )
}

/// One row in the queue sheet.
struct PlaybackQueueItemViewItem: Identifiable, Equatable {
    let id: String
    let title: String
    let sourceName: String
    let isCurrent: Bool
    let isDigest: Bool
}

/// Events emitted by the mini player and queue sheet.
enum PlaybackViewEvent: Equatable {
    case onPlayPauseTapped
    case onNextTapped
    case onPreviousTapped
    case onStopTapped
    case onSpeedTapped
    case onExpandTapped
    case onQueueSheetDismissed
    case onQueueItemTapped(itemID: String)
}
