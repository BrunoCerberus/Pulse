import AVFoundation
@preconcurrency import Combine
import EntropyCore
import Foundation
import MediaPlayer

/// Live implementation of `TextToSpeechService` using `AVSpeechSynthesizer`.
final class LiveTextToSpeechService: NSObject, TextToSpeechService, @unchecked Sendable {
    private nonisolated(unsafe) let synthesizer = AVSpeechSynthesizer()
    private nonisolated(unsafe) let playbackStateSubject = CurrentValueSubject<TTSPlaybackState, Never>(.idle)
    private nonisolated(unsafe) let progressSubject = CurrentValueSubject<Double, Never>(0.0)
    private nonisolated(unsafe) var totalTextLength: Int = 0
    private nonisolated(unsafe) var remoteCommandsRegistered = false

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

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, rate: Float) {
        // `AVSpeechSynthesizer` + `AVAudioSession` must be driven from the main
        // thread. Callers (the `@MainActor` interactor) are already on main, so
        // `runOnMain` executes synchronously and preserves ordering (including the
        // internal `stop()` below); remote-command handlers hop here from a
        // background queue. This collapses the synthesizer to a single-threaded driver.
        runOnMain {
            self.stop()

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

            self.configureNowPlayingInfo(for: text)
            self.registerRemoteCommandsIfNeeded()
        }
    }

    func pause() {
        runOnMain {
            guard self.synthesizer.isSpeaking else { return }
            self.synthesizer.pauseSpeaking(at: .word)
            self.playbackStateSubject.send(.paused)
            self.updateNowPlayingPlaybackRate(0.0)
        }
    }

    func resume() {
        runOnMain {
            guard self.synthesizer.isPaused else { return }
            self.synthesizer.continueSpeaking()
            self.playbackStateSubject.send(.playing)
            self.updateNowPlayingPlaybackRate(1.0)
        }
    }

    func stop() {
        runOnMain {
            // Clean-up must be idempotent: if `speak()` configured Now Playing / remote commands
            // but the synthesizer never reached a speaking state (rare race), an early-return
            // here would leave the Lock Screen entry orphaned. Always tear down session/state.
            let wasActive = self.synthesizer.isSpeaking || self.synthesizer.isPaused
            if wasActive {
                self.setActiveUtterance(nil)
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            self.playbackStateSubject.send(.idle)
            self.progressSubject.send(0.0)
            self.deactivateAudioSession()
            self.clearNowPlayingInfo()
        }
    }

    // MARK: - Private

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
                category: "Audio"
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
                category: "Audio"
            )
        }
    }

    // MARK: - MPNowPlayingInfoCenter

    /// Populates `MPNowPlayingInfoCenter.default()` so the system media controls
    /// (Lock Screen, Control Center, Dynamic Island media chip) reflect the
    /// currently-playing TTS session. Failures are silently swallowed.
    private func configureNowPlayingInfo(for text: String) {
        let titlePreview = String(text.prefix(80))
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = titlePreview
        info[MPMediaItemPropertyArtist] = "Pulse"
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackRate(_ rate: Double) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        unregisterRemoteCommands()
    }

    /// Registers remote command handlers exactly once. Subsequent invocations
    /// are no-ops, so command targets aren't registered multiple times.
    private func registerRemoteCommandsIfNeeded() {
        guard !remoteCommandsRegistered else { return }
        remoteCommandsRegistered = true

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.resume()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pause()
            return .success
        }

        center.stopCommand.isEnabled = true
        center.stopCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.stop()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            // Read `isSpeaking`/`isPaused` and act on the main thread: this handler
            // fires off-main and the synthesizer must only be inspected/driven there.
            DispatchQueue.main.async {
                if self.synthesizer.isSpeaking, !self.synthesizer.isPaused {
                    self.pause()
                } else {
                    self.resume()
                }
            }
            return .success
        }
    }

    private func unregisterRemoteCommands() {
        guard remoteCommandsRegistered else { return }
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = false
        center.pauseCommand.isEnabled = false
        center.stopCommand.isEnabled = false
        center.togglePlayPauseCommand.isEnabled = false
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.stopCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandsRegistered = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LiveTextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(
        _: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
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
        deactivateAudioSession()
        clearNowPlayingInfo()
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard isActiveUtterance(utterance) else { return }
        clearActiveUtterance(ifEquals: utterance)
        progressSubject.send(0.0)
        playbackStateSubject.send(.idle)
        deactivateAudioSession()
        clearNowPlayingInfo()
    }
}
