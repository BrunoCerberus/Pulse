import Foundation

// MARK: - Constants

extension SpeechPlayerBarView {
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

        static var speedLabel: String {
            AppLocalization.localized("tts.speed_label")
        }

        static var speedHint: String {
            AppLocalization.localized("tts.speed_hint")
        }

        static var stop: String {
            AppLocalization.localized("tts.stop")
        }
    }
}
