import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget

/// Live Activity that displays Text-to-Speech playback on the Lock Screen and
/// in the Dynamic Island. The widget is purely visual — interactive controls
/// would require an `AppIntent`, which is wired separately.
struct TTSLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TTSActivityAttributes.self) { context in
            // Lock Screen / banner presentation. The view itself is defined in
            // the shared LiveActivities folder so it can be snapshot-tested.
            TTSLockScreenView(
                state: context.state,
                articleTitle: context.attributes.articleTitle,
                sourceName: context.attributes.sourceName
            )
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(.white)
                        Text(context.attributes.sourceName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.speedLabel)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.articleTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .foregroundStyle(.white)

                        ProgressView(value: context.state.progress)
                            .tint(.white)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(width: 18, height: 18)
            } minimal: {
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
            }
            .keylineTint(.white)
        }
    }
}

// MARK: - Previews

#Preview(
    "TTS Live Activity",
    as: .content,
    using: TTSActivityAttributes(
        articleTitle: "SwiftUI 6.0 Brings Revolutionary New Features",
        sourceName: "TechCrunch"
    )
) {
    TTSLiveActivity()
} contentStates: {
    TTSActivityAttributes.ContentState(isPlaying: true, progress: 0.35, speedLabel: "1x")
    TTSActivityAttributes.ContentState(isPlaying: false, progress: 0.7, speedLabel: "1.25x")
}
