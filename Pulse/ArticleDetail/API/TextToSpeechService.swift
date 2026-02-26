import Combine
import Foundation

/// Playback state for text-to-speech.
enum TTSPlaybackState: Equatable {
    case idle
    case playing
    case paused
}

/// Speed presets for text-to-speech playback.
/// Each preset maps to an `AVSpeechUtterance.rate` multiplier.
enum TTSSpeedPreset: Equatable, CaseIterable {
    case normal
    case fast
    case faster
    case fastest

    /// Display label for the speed preset.
    var label: String {
        switch self {
        case .normal: "1x"
        case .fast: "1.25x"
        case .faster: "1.5x"
        case .fastest: "2x"
        }
    }

    /// Speech rate value for `AVSpeechUtterance.rate`.
    /// `AVSpeechUtteranceDefaultSpeechRate` is approximately 0.5.
    var rate: Float {
        let base: Float = 0.5
        return switch self {
        case .normal: base
        case .fast: base * 1.25
        case .faster: base * 1.5
        case .fastest: base * 2.0
        }
    }

    /// Returns the next speed preset in the cycle.
    func next() -> TTSSpeedPreset {
        let all = TTSSpeedPreset.allCases
        guard let index = all.firstIndex(of: self) else { return .normal }
        let nextIndex = (index + 1) % all.count
        return all[nextIndex]
    }
}

/// Protocol for text-to-speech operations.
protocol TextToSpeechService: AnyObject {
    /// Publisher for the current playback state.
    var playbackStatePublisher: AnyPublisher<TTSPlaybackState, Never> { get }

    /// Publisher for speech progress (0.0 to 1.0).
    var progressPublisher: AnyPublisher<Double, Never> { get }

    /// Start speaking the given text.
    /// - Parameters:
    ///   - text: The text to speak.
    ///   - language: ISO 639-1 language code (e.g., "en", "pt", "es").
    ///   - rate: Speech rate from `TTSSpeedPreset.rate`.
    func speak(text: String, language: String, rate: Float)

    /// Pause the current speech.
    func pause()

    /// Resume paused speech.
    func resume()

    /// Stop and cancel all speech.
    func stop()
}
