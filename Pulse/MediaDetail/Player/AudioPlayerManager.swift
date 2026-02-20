import AVFoundation
import Combine
import EntropyCore
import Foundation

/// Manages AVPlayer for podcast audio playback.
///
/// This manager wraps AVPlayer and publishes playback state changes
/// that the view can observe and forward to the ViewModel.
///
/// ## Usage
/// ```swift
/// @StateObject private var playerManager = AudioPlayerManager()
///
/// playerManager.load(url: podcastURL)
/// playerManager.play()
/// ```
@MainActor
final class AudioPlayerManager: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isLoading = true
    @Published private(set) var error: String?

    // MARK: - Private Properties

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var durationObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?

    // MARK: - Initialization

    init() {}

    deinit {
        // Perform cleanup inline since deinit is nonisolated
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        statusObserver?.invalidate()
        durationObserver?.invalidate()
        rateObserver?.invalidate()
        player?.pause()
        player = nil
        playerItem = nil
        timeObserver = nil
        statusObserver = nil
        durationObserver = nil
        rateObserver = nil
    }

    // MARK: - Audio Session

    /// Configures and activates the audio session for playback.
    /// Called lazily when loading audio to avoid simulator issues.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use simple .playback category with .default mode for maximum compatibility
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            // Log but don't fail - some devices may have restrictions
            Logger.shared.warning(
                "Audio session configuration warning: \(error.localizedDescription)",
                category: "Audio"
            )
        }
    }

    /// Deactivates the audio session when done.
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation errors
        }
    }

    // MARK: - Player Control

    /// Loads audio from the given URL.
    func load(url: URL) {
        cleanup()

        Logger.shared.debug("AudioPlayerManager: Loading URL: \(url.absoluteString)", category: "Audio")

        // Configure audio session before loading
        configureAudioSession()

        isLoading = true
        error = nil

        // Create asset - use simple initialization for better compatibility
        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        setupObservers()
    }

    /// Starts or resumes playback.
    func play() {
        player?.play()
    }

    /// Pauses playback.
    func pause() {
        player?.pause()
    }

    /// Seeks to a position (0.0 - 1.0).
    func seek(to progress: Double) {
        guard let player, duration > 0 else { return }

        let targetTime = CMTime(seconds: duration * progress, preferredTimescale: 600)
        player.seek(to: targetTime) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = targetTime.seconds
                self?.progress = progress
            }
        }
    }

    /// Skips backward by the specified number of seconds.
    func skipBackward(seconds: Double) {
        guard let player else { return }

        let newTime = max(0, currentTime - seconds)
        let targetTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    /// Skips forward by the specified number of seconds.
    func skipForward(seconds: Double) {
        guard let player else { return }

        let newTime = min(duration, currentTime + seconds)
        let targetTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    /// Cleans up player resources.
    func cleanup() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil

        statusObserver?.invalidate()
        statusObserver = nil

        durationObserver?.invalidate()
        durationObserver = nil

        rateObserver?.invalidate()
        rateObserver = nil

        player?.pause()
        player = nil
        playerItem = nil

        // Deactivate audio session
        deactivateAudioSession()
    }

    // MARK: - Observers

    private func setupObservers() {
        guard let player, let playerItem else { return }

        // Observe player item status
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.loadDuration()
                case .failed:
                    self?.isLoading = false
                    self?.error = item.error?.localizedDescription ?? "Failed to load audio"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Observe rate for play/pause state
        rateObserver = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = player.rate > 0
            }
        }

        // Observe time updates (every 0.5 seconds)
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.duration > 0 else { return }
                self.currentTime = time.seconds
                self.progress = time.seconds / self.duration
            }
        }
    }

    private func loadDuration() {
        guard let playerItem else { return }

        Task {
            do {
                let loadedDuration = try await playerItem.asset.load(.duration)
                let seconds = loadedDuration.seconds
                if seconds.isFinite && seconds > 0 {
                    await MainActor.run {
                        self.duration = seconds
                    }
                }
            } catch {
                // Duration loading failed, use playerItem duration as fallback
                if playerItem.duration.seconds.isFinite {
                    duration = playerItem.duration.seconds
                }
            }
        }
    }
}
