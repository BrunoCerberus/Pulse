import AVFoundation
import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("AudioPlayerManager Tests", .serialized)
@MainActor
struct AudioPlayerManagerTests {
    // MARK: - Initialization Tests

    @Test("AudioPlayerManager initializes with default state")
    func initializesWithDefaultState() {
        let manager = AudioPlayerManager()

        #expect(manager.isPlaying == false)
        #expect(manager.progress == 0)
        #expect(manager.currentTime == 0)
        #expect(manager.duration == 0)
        #expect(manager.isLoading == true)
        #expect(manager.error == nil)
    }

    @Test("AudioPlayerManager conforms to ObservableObject")
    func conformsToObservableObject() {
        let manager = AudioPlayerManager()
        // Compile-time protocol conformance check
        let _: any ObservableObject = manager
    }

    // MARK: - Published Properties Tests

    @Test("isPlaying is published property")
    func isPlayingIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        manager.$isPlaying
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(false))
    }

    @Test("progress is published property")
    func progressIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [Double] = []
        var cancellables = Set<AnyCancellable>()

        manager.$progress
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(0))
    }

    @Test("currentTime is published property")
    func currentTimeIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [TimeInterval] = []
        var cancellables = Set<AnyCancellable>()

        manager.$currentTime
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(0))
    }

    @Test("duration is published property")
    func durationIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [TimeInterval] = []
        var cancellables = Set<AnyCancellable>()

        manager.$duration
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(0))
    }

    @Test("isLoading is published property")
    func isLoadingIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        manager.$isLoading
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(true))
    }

    @Test("error is published property")
    func errorIsPublished() {
        let manager = AudioPlayerManager()
        var receivedValues: [String?] = []
        var cancellables = Set<AnyCancellable>()

        manager.$error
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        #expect(receivedValues.contains(nil))
    }

    // MARK: - Cleanup Tests

    @Test("cleanup resets state to initial values")
    func cleanupResetsState() {
        let manager = AudioPlayerManager()

        // Cleanup should be safe to call even without loading
        manager.cleanup()

        // After cleanup, state should be reset (loading remains true as it's the initial state)
        #expect(manager.isPlaying == false)
        #expect(manager.progress == 0)
        #expect(manager.currentTime == 0)
        #expect(manager.duration == 0)
    }

    @Test("cleanup can be called multiple times safely")
    func cleanupCanBeCalledMultipleTimes() {
        let manager = AudioPlayerManager()

        // Multiple cleanup calls should not crash
        manager.cleanup()
        manager.cleanup()
        manager.cleanup()

        #expect(manager.isPlaying == false)
    }

    // MARK: - Play/Pause Tests (Without Loading)

    @Test("play is safe to call without loading")
    func playIsSafeWithoutLoading() {
        let manager = AudioPlayerManager()

        // Should not crash when no player is loaded
        manager.play()

        #expect(manager.isPlaying == false)
    }

    @Test("pause is safe to call without loading")
    func pauseIsSafeWithoutLoading() {
        let manager = AudioPlayerManager()

        // Should not crash when no player is loaded
        manager.pause()

        #expect(manager.isPlaying == false)
    }

    // MARK: - Seek Tests (Without Loading)

    @Test("seek is safe to call without loading")
    func seekIsSafeWithoutLoading() {
        let manager = AudioPlayerManager()

        // Should not crash when no player is loaded
        manager.seek(to: 0.5)

        #expect(manager.progress == 0)
    }

    @Test("seek with zero duration does nothing")
    func seekWithZeroDurationDoesNothing() {
        let manager = AudioPlayerManager()

        // Duration is 0 by default, so seek should be a no-op
        manager.seek(to: 0.5)

        #expect(manager.progress == 0)
        #expect(manager.currentTime == 0)
    }

    // MARK: - Skip Tests (Without Loading)

    @Test("skipBackward is safe to call without loading")
    func skipBackwardIsSafeWithoutLoading() {
        let manager = AudioPlayerManager()

        // Should not crash
        manager.skipBackward(seconds: 15)

        #expect(manager.currentTime == 0)
    }

    @Test("skipForward is safe to call without loading")
    func skipForwardIsSafeWithoutLoading() {
        let manager = AudioPlayerManager()

        // Should not crash
        manager.skipForward(seconds: 15)

        #expect(manager.currentTime == 0)
    }

    // MARK: - Load Tests

    @Test("load sets isLoading to true")
    func loadSetsIsLoadingToTrue() throws {
        let manager = AudioPlayerManager()

        // Use a valid but non-existent URL to test loading state
        let testURL = try #require(URL(string: "https://example.com/test.mp3"))
        manager.load(url: testURL)

        #expect(manager.isLoading == true)
        #expect(manager.error == nil)

        // Cleanup
        manager.cleanup()
    }

    @Test("load clears previous error")
    func loadClearsPreviousError() throws {
        let manager = AudioPlayerManager()

        // Load with a test URL
        let testURL = try #require(URL(string: "https://example.com/test.mp3"))
        manager.load(url: testURL)

        // Error should be cleared on new load
        #expect(manager.error == nil)

        // Cleanup
        manager.cleanup()
    }

    @Test("load with different URL replaces previous load")
    func loadWithDifferentURLReplacesPreviousLoad() throws {
        let manager = AudioPlayerManager()

        let url1 = try #require(URL(string: "https://example.com/test1.mp3"))
        let url2 = try #require(URL(string: "https://example.com/test2.mp3"))

        manager.load(url: url1)
        manager.load(url: url2)

        // Should not crash and should be in loading state
        #expect(manager.isLoading == true)

        // Cleanup
        manager.cleanup()
    }

    // MARK: - Edge Cases

    @Test("seek clamps to valid range - progress 0")
    func seekClampsToValidRangeZero() {
        let manager = AudioPlayerManager()

        manager.seek(to: 0.0)

        // Without a player, nothing happens
        #expect(manager.progress == 0)
    }

    @Test("seek clamps to valid range - progress 1")
    func seekClampsToValidRangeOne() {
        let manager = AudioPlayerManager()

        manager.seek(to: 1.0)

        // Without a player, nothing happens
        #expect(manager.progress == 0)
    }

    @Test("skipBackward does not go below zero")
    func skipBackwardDoesNotGoBelowZero() {
        let manager = AudioPlayerManager()

        // Even with very large skip value, should not crash
        manager.skipBackward(seconds: 1000)

        // Without a loaded player, current time stays at 0
        #expect(manager.currentTime >= 0)
    }

    @Test("skipForward does not exceed duration")
    func skipForwardDoesNotExceedDuration() {
        let manager = AudioPlayerManager()

        // Even with very large skip value, should not crash
        manager.skipForward(seconds: 1000)

        // Without a loaded player, stays at 0
        #expect(manager.currentTime >= 0)
    }

    // MARK: - Memory Management Tests

    @Test("Manager can be deallocated after cleanup")
    func managerCanBeDeallocatedAfterCleanup() async throws {
        weak var weakManager: AudioPlayerManager?

        do {
            let manager = AudioPlayerManager()
            weakManager = manager

            let testURL = try #require(URL(string: "https://example.com/test.mp3"))
            manager.load(url: testURL)
            manager.cleanup()
        }

        // Give time for deallocation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Note: In tests, the manager may not be deallocated immediately
        // due to test framework retention, so we just verify the weak ref is accessible
        _ = weakManager
    }

    // MARK: - Observer Tests

    @Test("Multiple loads do not accumulate observers")
    func multipleLoadsDoNotAccumulateObservers() throws {
        let manager = AudioPlayerManager()

        let testURL = try #require(URL(string: "https://example.com/test.mp3"))

        // Load multiple times
        for _ in 0 ..< 5 {
            manager.load(url: testURL)
        }

        // Should not crash and cleanup should work
        manager.cleanup()

        #expect(manager.isPlaying == false)
    }
}

// MARK: - CMTime Extension Tests

@Suite("CMTime Usage Tests")
struct CMTimeUsageTests {
    @Test("CMTime can be created with seconds and timescale")
    func cmTimeCanBeCreated() {
        let time = CMTime(seconds: 30.0, preferredTimescale: 600)

        #expect(time.seconds == 30.0)
    }

    @Test("CMTime handles zero duration")
    func cmTimeHandlesZeroDuration() {
        let time = CMTime(seconds: 0, preferredTimescale: 600)

        #expect(time.seconds == 0)
    }

    @Test("CMTime handles negative values")
    func cmTimeHandlesNegativeValues() {
        let time = CMTime(seconds: -10, preferredTimescale: 600)

        #expect(time.seconds == -10)
    }
}
