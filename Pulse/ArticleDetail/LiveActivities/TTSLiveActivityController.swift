@preconcurrency import ActivityKit
import EntropyCore
import Foundation

/// Singleton controller that owns the lifecycle of the Text-to-Speech
/// `Activity<TTSActivityAttributes>`.
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

    private init() {}

    // MARK: - Lifecycle

    /// Starts a new Live Activity for the given article. No-op if a previous
    /// activity is still active or if Live Activities are unavailable.
    ///
    /// - Parameters:
    ///   - articleTitle: Title displayed inside the activity.
    ///   - sourceName: Source name shown above the title.
    ///   - speedLabel: Initial speed preset label (e.g. `"1x"`).
    func start(articleTitle: String, sourceName: String, speedLabel: String) {
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

        let attributes = TTSActivityAttributes(
            articleTitle: articleTitle,
            sourceName: sourceName
        )
        let initialState = TTSActivityAttributes.ContentState(
            isPlaying: true,
            progress: 0.0,
            speedLabel: speedLabel
        )

        do {
            let activity = try Activity<TTSActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
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
    func update(isPlaying: Bool, progress: Double, speedLabel: String) async {
        guard let activity = currentActivity else { return }

        let clampedProgress = min(max(progress, 0.0), 1.0)
        let newState = TTSActivityAttributes.ContentState(
            isPlaying: isPlaying,
            progress: clampedProgress,
            speedLabel: speedLabel
        )

        await activity.update(ActivityContent(state: newState, staleDate: nil))
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
}
