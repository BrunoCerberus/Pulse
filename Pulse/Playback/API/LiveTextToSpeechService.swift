import AVFoundation
@preconcurrency import Combine
import EntropyCore
import Foundation

/// Live implementation of `TextToSpeechService` using `AVSpeechSynthesizer`.
///
/// This service is a dumb synthesizer + audio-session driver. System media
/// integration (Now Playing metadata, remote commands) is owned by
/// `LivePlaybackQueueService`, which is the single consumer of this service.
final class LiveTextToSpeechService: NSObject, TextToSpeechService, @unchecked Sendable {
    private nonisolated(unsafe) let synthesizer = AVSpeechSynthesizer()
    private nonisolated(unsafe) let playbackStateSubject = CurrentValueSubject<TTSPlaybackState, Never>(.idle)
    private nonisolated(unsafe) let progressSubject = CurrentValueSubject<Double, Never>(0.0)
    private nonisolated(unsafe) let didFinishSubject = PassthroughSubject<Void, Never>()
    private nonisolated(unsafe) var totalTextLength: Int = 0

    /// Thread-safe reference to the utterance currently being spoken.
    /// Delegate callbacks for any other utterance are silently discarded.
    private let utteranceLock = NSLock()
    private nonisolated(unsafe) var _activeUtterance: AVSpeechUtterance?

    var playbackStatePublisher: AnyPublisher<TTSPlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    var didFinishUtterancePublisher: AnyPublisher<Void, Never> {
        didFinishSubject.eraseToAnyPublisher()
    }

    var currentPlaybackState: TTSPlaybackState {
        playbackStateSubject.value
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, rate: Float) {
        // `AVSpeechSynthesizer` + `AVAudioSession` must be driven from the main
        // thread. Callers (the `@MainActor` queue service) are already on main, so
        // `runOnMain` executes synchronously and preserves ordering (including the
        // internal cancellation below); this collapses the synthesizer to a
        // single-threaded driver.
        runOnMain {
            // Cancel without deactivating the audio session: back-to-back speak()
            // calls (queue auto-advance, speed change) must not bounce the session,
            // which can fail with `AVAudioSessionErrorCodeIsBusy` in the background.
            self.cancelCurrentUtterance()

            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = rate
            utterance.voice = AVSpeechSynthesisVoice(language: self.voiceLanguage(for: language))
            utterance.pitchMultiplier = 1.0
            utterance.preUtteranceDelay = 0.1

            self.totalTextLength = text.count
            self.setActiveUtterance(utterance)
            self.progressSubject.send(0.0)

            self.configureAudioSession()
            self.synthesizer.speak(utterance)
            self.playbackStateSubject.send(.playing)
        }
    }

    func pause() {
        runOnMain {
            guard self.synthesizer.isSpeaking else { return }
            self.synthesizer.pauseSpeaking(at: .word)
            self.playbackStateSubject.send(.paused)
        }
    }

    func resume() {
        runOnMain {
            guard self.synthesizer.isPaused else { return }
            // The system can deactivate our session while paused (audio
            // interruptions); reactivating before continueSpeaking avoids
            // silently "playing" into a dead session. Re-activating an
            // already-active session is a no-op.
            self.configureAudioSession()
            self.synthesizer.continueSpeaking()
            self.playbackStateSubject.send(.playing)
        }
    }

    func stop() {
        runOnMain {
            self.cancelCurrentUtterance()
            self.playbackStateSubject.send(.idle)
            self.progressSubject.send(0.0)
            // The session is deactivated only here — never between utterances —
            // so other apps' audio resumes exactly when playback explicitly ends.
            self.deactivateAudioSession()
        }
    }

    // MARK: - Private

    /// Stops the synthesizer and clears the active utterance without touching
    /// the audio session or publishing state. Idempotent.
    private func cancelCurrentUtterance() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        setActiveUtterance(nil)
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Runs `work` on the main thread, synchronously if already on main so call
    /// ordering is preserved, otherwise dispatched. All synthesizer / audio-session
    /// mutations funnel through here so activate/deactivate never interleave across
    /// threads (which can surface as silent playback or a swallowed
    /// `AVAudioSessionErrorCodeIsBusy`).
    private func runOnMain(_ work: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func setActiveUtterance(_ utterance: AVSpeechUtterance?) {
        utteranceLock.lock()
        _activeUtterance = utterance
        utteranceLock.unlock()
    }

    private func isActiveUtterance(_ utterance: AVSpeechUtterance) -> Bool {
        utteranceLock.lock()
        defer { utteranceLock.unlock() }
        return _activeUtterance === utterance
    }

    private func clearActiveUtterance(ifEquals utterance: AVSpeechUtterance) {
        utteranceLock.lock()
        if _activeUtterance === utterance {
            _activeUtterance = nil
        }
        utteranceLock.unlock()
    }

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
            // Non-fatal: speech will still work without explicit session config.
            Logger.shared.warning(
                "TTS audio session activation failed: \(error.localizedDescription)",
                category: "Audio",
            )
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Non-fatal.
            Logger.shared.warning(
                "TTS audio session deactivation failed: \(error.localizedDescription)",
                category: "Audio",
            )
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LiveTextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(
        _: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance,
    ) {
        guard isActiveUtterance(utterance), totalTextLength > 0 else { return }
        let progress = Double(characterRange.location + characterRange.length) / Double(totalTextLength)
        progressSubject.send(min(progress, 1.0))
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard isActiveUtterance(utterance) else { return }
        clearActiveUtterance(ifEquals: utterance)
        progressSubject.send(1.0)
        playbackStateSubject.send(.idle)
        // The audio session stays active here so a queue consumer can speak the
        // next item immediately (gapless auto-advance, works while backgrounded).
        // Finish fires after the state settles so consumers reacting to it
        // observe a consistent idle state.
        didFinishSubject.send(())
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard isActiveUtterance(utterance) else { return }
        clearActiveUtterance(ifEquals: utterance)
        progressSubject.send(0.0)
        playbackStateSubject.send(.idle)
    }
}
