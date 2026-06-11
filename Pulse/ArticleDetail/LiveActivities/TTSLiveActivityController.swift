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

    /// Maximum length for title/source strings written into the Live Activity.
    /// The Lock Screen / Dynamic Island truncate visually, but a pathologically
    /// long title (rare RSS edge case) can otherwise dominate the snapshot the
    /// OS captures for the app switcher, and ContentState updates have a 4 KB
    /// payload budget.
    private static let maxLabelLength = 100

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
    func start(currentTitle: String, currentSource: String, speedLabel: String, queuePosition: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.shared.service(
                "TTSLiveActivityController: Live Activities not enabled, skipping start",
                level: .info
            )
            return
        }

        // If an activity is already active, end it first so we don't leak.
        if currentActivity != nil {
            end()
        }

        let initialState = Self.contentState(
            isPlaying: true,
            progress: 0.0,
            speedLabel: speedLabel,
            currentTitle: currentTitle,
            currentSource: currentSource,
            queuePosition: queuePosition
        )

        do {
            let activity = try Activity<TTSActivityAttributes>.request(
                attributes: TTSActivityAttributes(),
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(Self.staleInterval)),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            Logger.shared.service(
                "TTSLiveActivityController: failed to start activity: \(error)",
                level: .warning
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
        currentTitle: String,
        currentSource: String,
        queuePosition: String?
    ) async {
        guard let activity = currentActivity else { return }

        let newState = Self.contentState(
            isPlaying: isPlaying,
            progress: progress,
            speedLabel: speedLabel,
            currentTitle: currentTitle,
            currentSource: currentSource,
            queuePosition: queuePosition
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
        currentTitle: String,
        currentSource: String,
        queuePosition: String?
    ) -> TTSActivityAttributes.ContentState {
        TTSActivityAttributes.ContentState(
            isPlaying: isPlaying,
            progress: min(max(progress, 0.0), 1.0),
            speedLabel: speedLabel,
            currentTitle: String(currentTitle.prefix(maxLabelLength)),
            currentSource: String(currentSource.prefix(maxLabelLength)),
            queuePosition: queuePosition
        )
    }
}
