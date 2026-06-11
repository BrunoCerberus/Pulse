import Foundation

// MARK: - Constants

extension PlaybackQueueSheet {
    enum Constants {
        static var title: String {
            AppLocalization.localized("player.queue_title")
        }

        static var stop: String {
            AppLocalization.localized("tts.stop")
        }

        static var speedLabel: String {
            AppLocalization.localized("tts.speed_label")
        }

        static var speedHint: String {
            AppLocalization.localized("tts.speed_hint")
        }

        static var currentItemHint: String {
            AppLocalization.localized("player.current_item_hint")
        }

        static var jumpHint: String {
            AppLocalization.localized("player.jump_hint")
        }
    }
}
