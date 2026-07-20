import SwiftUI

/// Lock Screen / banner presentation for the TTS Live Activity, extracted as a
/// standalone `View` so it can be snapshot-tested in isolation without rendering
/// the surrounding `ActivityConfiguration`.
///
/// This file lives in the shared `LiveActivities` folder and is compiled into
/// BOTH the main Pulse app target and the PulseWidgetExtension target.
struct TTSLockScreenView: View {
    let state: TTSActivityAttributes.ContentState

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(state.currentSource)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            if let queuePosition = state.queuePosition {
                                Text(queuePosition)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(state.currentTitle)
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

#Preview("Playing - Briefing") {
    TTSLockScreenView(
        state: .init(
            isPlaying: true,
            progress: 0.35,
            speedLabel: "1x",
            currentTitle: "SwiftUI 6.0 Brings Revolutionary New Features",
            currentSource: "TechCrunch",
            queuePosition: "2/11",
        ),
    )
    .padding()
    .background(Color.black)
}

#Preview("Paused - Single Article") {
    TTSLockScreenView(
        state: .init(
            isPlaying: false,
            progress: 0.7,
            speedLabel: "1.25x",
            currentTitle: "Markets Rally on Economic News",
            currentSource: "Financial Times",
            queuePosition: nil,
        ),
    )
    .padding()
    .background(Color.black)
}
