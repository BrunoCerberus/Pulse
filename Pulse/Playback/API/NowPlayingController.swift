import Foundation
import MediaPlayer

/// Owns the system media surface for the playback queue: Now Playing metadata
/// (Lock Screen, Control Center, Dynamic Island media chip) and remote
/// commands, including next/previous track when a briefing queue is active.
///
/// Owned exclusively by `LivePlaybackQueueService`, which pushes every state
/// change through `update(with:)`.
@MainActor
final class NowPlayingController {
    private weak var service: PlaybackQueueService?
    private var commandsRegistered = false

    /// Wires the controller back to its owning service. Separate from `init`
    /// because the service constructs the controller before `self` is available.
    func attach(to service: PlaybackQueueService) {
        self.service = service
    }

    /// Mirrors the queue state into `MPNowPlayingInfoCenter` and toggles
    /// command availability. Clears everything when the queue goes inactive.
    func update(with state: PlaybackQueueState) {
        guard state.currentIndex != nil, let item = state.currentItem else {
            clear()
            return
        }

        registerCommandsIfNeeded()

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: item.sourceName,
            MPNowPlayingInfoPropertyPlaybackRate: state.playbackState == .playing ? 1.0 : 0.0,
        ]
        if state.mode == .briefing, let index = state.currentIndex {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index
            info[MPNowPlayingInfoPropertyPlaybackQueueCount] = state.items.count
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = state.hasNext
        center.previousTrackCommand.isEnabled = state.hasPrevious
    }

    private func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        unregisterCommands()
    }

    // MARK: - Remote Commands

    /// Registers command handlers exactly once per active session. Handlers
    /// fire on a background queue, so they hop to the main actor via a
    /// `WeakRef` (non-Sendable `self` can't be captured in a `@Sendable` Task).
    private func registerCommandsIfNeeded() {
        guard !commandsRegistered else { return }
        commandsRegistered = true

        let center = MPRemoteCommandCenter.shared()
        let ref = WeakRef(self)

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { _ in
            Task { @MainActor in
                guard let controller = ref.object,
                      controller.service?.currentState.playbackState == .paused
                else { return }
                controller.service?.togglePlayPause()
            }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { _ in
            Task { @MainActor in
                guard let controller = ref.object,
                      controller.service?.currentState.playbackState == .playing
                else { return }
                controller.service?.togglePlayPause()
            }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in
                ref.object?.service?.togglePlayPause()
            }
            return .success
        }

        center.stopCommand.isEnabled = true
        center.stopCommand.addTarget { _ in
            Task { @MainActor in
                ref.object?.service?.stop()
            }
            return .success
        }

        center.nextTrackCommand.addTarget { _ in
            Task { @MainActor in
                ref.object?.service?.next()
            }
            return .success
        }

        center.previousTrackCommand.addTarget { _ in
            Task { @MainActor in
                ref.object?.service?.previous()
            }
            return .success
        }
    }

    private func unregisterCommands() {
        guard commandsRegistered else { return }
        commandsRegistered = false

        let center = MPRemoteCommandCenter.shared()
        let commands: [MPRemoteCommand] = [
            center.playCommand,
            center.pauseCommand,
            center.togglePlayPauseCommand,
            center.stopCommand,
            center.nextTrackCommand,
            center.previousTrackCommand,
        ]
        for command in commands {
            command.isEnabled = false
            command.removeTarget(nil)
        }
    }
}
