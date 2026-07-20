@preconcurrency import ActivityKit
import EntropyCore
import Foundation

/// Singleton controller that owns the lifecycle of the Text-to-Speech
/// `Activity<TTSActivityAttributes>`.
///
/// One activity spans an entire playback session (a briefing queue or a single
/// article); item changes are pushed as `ContentState` updates rather than
/// restarting the activity, so the Lock Screen presentation never flickers.
///
/// All ActivityKit calls are guarded so the controller can be safely invoked
/// even when Live Activities are disabled by the user, when running on a
/// device/OS that does not support them, or when ActivityKit throws.
@MainActor
final class TTSLiveActivityController {
    static let shared = TTSLiveActivityController()

    /// Currently-running activity, if any.
    private var currentActivity: Activity<TTSActivityAttributes>?

    /// `true` while a Live Activity is currently being displayed.
    var isActive: Bool {
        currentActivity != nil
    }

    /// Display fields for a TTS Live Activity.
    struct PlaybackDisplayInfo {
        let title: String
        let source: String
        let position: String?

        func trimmed() -> Self {
            // `PromptSanitizer` is scoped to LLM prompts but its core
            // behaviour — control-char removal, length-capping, and stripping
            // of obfuscation characters (backticks, turn markers) — is also the
            // right defence-in-depth for any text rendered on-screen that
            // originates from untrusted RSS feeds.  The LLM-specific markers
            // are harmless no-ops in this context.
            .init(
                title: PromptSanitizer.sanitize(title, maxLength: Self.maxLabelLength),
                source: PromptSanitizer.sanitize(source, maxLength: Self.maxLabelLength),
                position: position,
            )
        }

        private static let maxLabelLength = 100
    }

    /// How far in the future to set each activity's `staleDate`. ActivityKit will
    /// auto-stale (and the OS can dismiss) an activity that isn't refreshed within
    /// this window — the safety net for an orphaned activity whose owning
    /// service was torn down without ending it. Refreshed on every `update`,
    /// which the TTS progress publisher fires frequently while playing.
    private static let staleInterval: TimeInterval = 5 * 60

    private init() {}

    // MARK: - Lifecycle

    /// Starts a new Live Activity for a playback session. No-op if Live
    /// Activities are unavailable; an already-active activity is ended first.
    ///
    /// - Parameters:
    ///   - currentTitle: Title of the item being narrated.
    ///   - currentSource: Source name shown above the title.
    ///   - speedLabel: Initial speed preset label (e.g. `"1x"`).
    ///   - queuePosition: Queue position label (e.g. `"1/11"`), or `nil` for
    ///     single-article playback.
    func start(displayInfo: PlaybackDisplayInfo, speedLabel: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.shared.service(
                "TTSLiveActivityController: Live Activities not enabled, skipping start",
                level: .info,
            )
            return
        }

        let initialState = Self.contentState(
            isPlaying: true,
            progress: 0.0,
            speedLabel: speedLabel,
            displayInfo: displayInfo,
        )
        let content = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(Self.staleInterval),
        )

        // Replacing a session: await the old activity's end before requesting
        // the new one so the Lock Screen never shows two TTS activities, even
        // transiently. Updates issued in that window no-op (no current
        // activity) and the next throttled progress sync repaints the state.
        if let previous = currentActivity {
            currentActivity = nil
            Task { @MainActor in
                await previous.end(nil, dismissalPolicy: .immediate)
                self.requestActivity(with: content)
            }
        } else {
            requestActivity(with: content)
        }
    }

    private func requestActivity(with content: ActivityContent<TTSActivityAttributes.ContentState>) {
        do {
            currentActivity = try Activity<TTSActivityAttributes>.request(
                attributes: TTSActivityAttributes(),
                content: content,
                pushType: nil,
            )
        } catch {
            Logger.shared.service(
                "TTSLiveActivityController: failed to start activity: \(error)",
                level: .warning,
            )
        }
    }

    /// Updates the active activity's `ContentState`. No-op if there is no
    /// active activity.
    ///
    /// `update` is `async` so callers on the main actor can `await` directly
    /// without each invocation paying for a fresh `Task` allocation. The TTS
    /// progress publisher fires on every character range from
    /// `AVSpeechSynthesizerDelegate`, so this is a hot path.
    func update(
        isPlaying: Bool,
        progress: Double,
        speedLabel: String,
        displayInfo: PlaybackDisplayInfo,
    ) async {
        guard let activity = currentActivity else { return }

        let newState = Self.contentState(
            isPlaying: isPlaying,
            progress: progress,
            speedLabel: speedLabel,
            displayInfo: displayInfo,
        )

        // Refresh the stale date on every update so a live, actively-updating
        // activity never goes stale, while an orphaned one (no further updates)
        // stales after `staleInterval`.
        let staleDate = Date().addingTimeInterval(Self.staleInterval)
        await activity.update(ActivityContent(state: newState, staleDate: staleDate))
    }

    /// Ends the current activity, if any. Safe to call when no activity exists.
    func end(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        guard currentActivity != nil else { return }
        // Clear the reference immediately so additional `end()` calls are no-ops.
        let activityToEnd = currentActivity
        currentActivity = nil

        Task { @MainActor in
            guard let activity = activityToEnd else { return }
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }
    }

    // MARK: - Private

    private static func contentState(
        isPlaying: Bool,
        progress: Double,
        speedLabel: String,
        displayInfo: PlaybackDisplayInfo,
    ) -> TTSActivityAttributes.ContentState {
        let trimmed = displayInfo.trimmed()
        return TTSActivityAttributes.ContentState(
            isPlaying: isPlaying,
            progress: min(max(progress, 0.0), 1.0),
            speedLabel: speedLabel,
            currentTitle: trimmed.title,
            currentSource: trimmed.source,
            queuePosition: trimmed.position,
        )
    }
}
