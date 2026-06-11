import Foundation

/// Domain state for the global playback player.
///
/// Mirrors the queue service's state and adds UI-coordination state owned by
/// this feature (queue sheet presentation).
struct PlaybackDomainState: Equatable {
    /// Latest snapshot from `PlaybackQueueService`.
    var queueState: PlaybackQueueState

    /// Whether the full queue sheet is presented.
    var isQueueSheetPresented: Bool

    static let initial = PlaybackDomainState(
        queueState: .idle,
        isQueueSheetPresented: false
    )
}
