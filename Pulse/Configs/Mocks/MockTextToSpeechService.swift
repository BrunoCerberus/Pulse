import Combine
import Foundation

final class MockTextToSpeechService: TextToSpeechService {
    private let playbackStateSubject = CurrentValueSubject<TTSPlaybackState, Never>(.idle)
    private let progressSubject = CurrentValueSubject<Double, Never>(0.0)

    // MARK: - Call Tracking

    private(set) var speakCallCount = 0
    private(set) var lastSpokenText: String?
    private(set) var lastLanguage: String?
    private(set) var lastRate: Float?
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var stopCallCount = 0

    // MARK: - Protocol

    var playbackStatePublisher: AnyPublisher<TTSPlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    func speak(text: String, language: String, rate: Float) {
        speakCallCount += 1
        lastSpokenText = text
        lastLanguage = language
        lastRate = rate
        playbackStateSubject.send(.playing)
    }

    func pause() {
        pauseCallCount += 1
        playbackStateSubject.send(.paused)
    }

    func resume() {
        resumeCallCount += 1
        playbackStateSubject.send(.playing)
    }

    func stop() {
        stopCallCount += 1
        playbackStateSubject.send(.idle)
        progressSubject.send(0.0)
    }

    // MARK: - Test Helpers

    func simulateProgress(_ value: Double) {
        progressSubject.send(value)
    }

    func simulateFinished() {
        progressSubject.send(1.0)
        playbackStateSubject.send(.idle)
    }

    func reset() {
        speakCallCount = 0
        lastSpokenText = nil
        lastLanguage = nil
        lastRate = nil
        pauseCallCount = 0
        resumeCallCount = 0
        stopCallCount = 0
        playbackStateSubject.send(.idle)
        progressSubject.send(0.0)
    }
}
