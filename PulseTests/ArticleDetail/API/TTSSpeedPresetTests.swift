import Foundation
@testable import Pulse
import Testing

@Suite("TTSSpeedPreset Tests")
struct TTSSpeedPresetTests {
    @Test("All presets have correct labels")
    func labels() {
        #expect(TTSSpeedPreset.normal.label == "1x")
        #expect(TTSSpeedPreset.fast.label == "1.25x")
        #expect(TTSSpeedPreset.faster.label == "1.5x")
        #expect(TTSSpeedPreset.fastest.label == "2x")
    }

    @Test("All presets have correct rates")
    func rates() {
        #expect(TTSSpeedPreset.normal.rate == 0.5)
        #expect(TTSSpeedPreset.fast.rate == 0.625)
        #expect(TTSSpeedPreset.faster.rate == 0.75)
        #expect(TTSSpeedPreset.fastest.rate == 1.0)
    }

    @Test("next() cycles through all presets in order")
    func nextCycles() {
        #expect(TTSSpeedPreset.normal.next() == .fast)
        #expect(TTSSpeedPreset.fast.next() == .faster)
        #expect(TTSSpeedPreset.faster.next() == .fastest)
        #expect(TTSSpeedPreset.fastest.next() == .normal)
    }

    @Test("allCases has expected count")
    func allCases() {
        #expect(TTSSpeedPreset.allCases.count == 4)
    }

    @Test("Presets are Equatable")
    func equatable() {
        #expect(TTSSpeedPreset.normal == .normal)
        #expect(TTSSpeedPreset.normal != .fast)
    }
}

@Suite("TTSPlaybackState Tests")
struct TTSPlaybackStateTests {
    @Test("States are Equatable")
    func equatable() {
        #expect(TTSPlaybackState.idle == .idle)
        #expect(TTSPlaybackState.playing == .playing)
        #expect(TTSPlaybackState.paused == .paused)
        #expect(TTSPlaybackState.idle != .playing)
        #expect(TTSPlaybackState.playing != .paused)
    }
}
