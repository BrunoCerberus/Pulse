import SwiftUI

/// Lock Screen / banner presentation for the TTS Live Activity, extracted as a
/// standalone `View` so it can be snapshot-tested in isolation without rendering
/// the surrounding `ActivityConfiguration`.
///
/// This file lives in the shared `LiveActivities` folder and is compiled into
/// BOTH the main Pulse app target and the PulseWidgetExtension target.
struct TTSLockScreenView: View {
    let state: TTSActivityAttributes.ContentState
    let articleTitle: String
    let sourceName: String

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sourceName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(articleTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 10) {
                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)

                        Text(state.speedLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular, in: .capsule)
                    }
                }

                ProgressView(value: state.progress)
                    .tint(.white)
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }
}

#Preview("Playing") {
    TTSLockScreenView(
        state: .init(isPlaying: true, progress: 0.35, speedLabel: "1x"),
        articleTitle: "SwiftUI 6.0 Brings Revolutionary New Features",
        sourceName: "TechCrunch"
    )
    .padding()
    .background(Color.black)
}

#Preview("Paused") {
    TTSLockScreenView(
        state: .init(isPlaying: false, progress: 0.7, speedLabel: "1.25x"),
        articleTitle: "Markets Rally on Economic News",
        sourceName: "Financial Times"
    )
    .padding()
    .background(Color.black)
}
