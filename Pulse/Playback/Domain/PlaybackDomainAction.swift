import Foundation

/// Actions that can be dispatched to the Playback domain interactor.
///
/// These actions control the global playback queue (mini player + queue
/// sheet); all playback mutations delegate to `PlaybackQueueService`.
enum PlaybackDomainAction: Equatable {
    // MARK: - Service State

    /// The playback queue service published a new state snapshot.
    case queueStateChanged(PlaybackQueueState)

    // MARK: - Transport Controls

    /// Pause if playing, resume if paused.
    case togglePlayPause

    /// Skip to the next queue item.
    case next

    /// Restart the previous queue item.
    case previous

    /// Jump to a specific queue item.
    case skipTo(itemID: String)

    /// Cycle the speech speed preset.
    case cycleSpeed

    /// Stop playback and dismiss the player.
    case stop

    // MARK: - Queue Sheet

    /// Present the full queue sheet.
    case showQueueSheet

    /// Dismiss the queue sheet.
    case dismissQueueSheet
}
