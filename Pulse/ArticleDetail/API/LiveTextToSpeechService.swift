import AVFoundation
import Combine
import Foundation

/// Live implementation of `TextToSpeechService` using `AVSpeechSynthesizer`.
final class LiveTextToSpeechService: NSObject, TextToSpeechService {
    private nonisolated(unsafe) let synthesizer = AVSpeechSynthesizer()
    private let playbackStateSubject = CurrentValueSubject<TTSPlaybackState, Never>(.idle)
    private let progressSubject = CurrentValueSubject<Double, Never>(0.0)
    private var totalTextLength: Int = 0

    var playbackStatePublisher: AnyPublisher<TTSPlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, rate: Float) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage(for: language))
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1

        totalTextLength = text.count
        progressSubject.send(0.0)

        configureAudioSession()
        synthesizer.speak(utterance)
        playbackStateSubject.send(.playing)
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        playbackStateSubject.send(.paused)
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        playbackStateSubject.send(.playing)
    }

    func stop() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        synthesizer.stopSpeaking(at: .immediate)
        playbackStateSubject.send(.idle)
        progressSubject.send(0.0)
        deactivateAudioSession()
    }

    // MARK: - Private

    private func voiceLanguage(for languageCode: String) -> String {
        switch languageCode {
        case "pt": "pt-BR"
        case "es": "es-ES"
        default: "en-US"
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            // Non-fatal: speech will still work without explicit session config
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Non-fatal
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LiveTextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(
        _: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance _: AVSpeechUtterance
    ) {
        guard totalTextLength > 0 else { return }
        let progress = Double(characterRange.location + characterRange.length) / Double(totalTextLength)
        progressSubject.send(min(progress, 1.0))
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        progressSubject.send(1.0)
        playbackStateSubject.send(.idle)
        deactivateAudioSession()
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        progressSubject.send(0.0)
        playbackStateSubject.send(.idle)
        deactivateAudioSession()
    }
}
