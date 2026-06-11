import Foundation

// MARK: - Constants

extension MiniPlayerView {
    enum Constants {
        static var progress: String {
            AppLocalization.localized("tts.progress")
        }

        static var progressValue: String {
            AppLocalization.localized("tts.progress_value")
        }

        static var pause: String {
            AppLocalization.localized("tts.pause")
        }

        static var play: String {
            AppLocalization.localized("tts.play")
        }

        static var listening: String {
            AppLocalization.localized("tts.listening")
        }

        static var next: String {
            AppLocalization.localized("tts.next")
        }

        static var speedLabel: String {
            AppLocalization.localized("tts.speed_label")
        }

        static var speedHint: String {
            AppLocalization.localized("tts.speed_hint")
        }

        static var stop: String {
            AppLocalization.localized("tts.stop")
        }

        static var expandHint: String {
            AppLocalization.localized("player.expand_hint")
        }

        static var playingAnnouncement: String {
            AppLocalization.localized("accessibility.tts_started")
        }

        static var pausedAnnouncement: String {
            AppLocalization.localized("accessibility.tts_paused")
        }
    }
}
