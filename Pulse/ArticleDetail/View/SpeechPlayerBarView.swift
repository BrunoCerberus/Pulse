import EntropyCore
import SwiftUI

struct SpeechPlayerBarView: View {
    let title: String
    let playbackState: TTSPlaybackState
    let progress: Double
    let speedPreset: TTSSpeedPreset
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onSpeedTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: progress)
                .tint(Color.Accent.gradient)
                .accessibilityLabel(AppLocalization.localized("tts.progress"))
                .accessibilityValue(
                    String(format: AppLocalization.localized("tts.progress_value"), Int(progress * 100))
                )

            HStack(spacing: Spacing.md) {
                Button(action: onPlayPause) {
                    Image(systemName: playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                }
                .accessibilityIdentifier("ttsPlayPauseButton")
                .accessibilityLabel(
                    playbackState == .playing
                        ? AppLocalization.localized("tts.pause")
                        : AppLocalization.localized("tts.play")
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppLocalization.localized("tts.listening"))
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(title)
                        .font(Typography.labelMedium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                Button(action: onSpeedTap) {
                    Text(speedPreset.label)
                        .font(Typography.labelMedium)
                        .monospacedDigit()
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
                .accessibilityIdentifier("ttsSpeedButton")
                .accessibilityLabel(
                    String(format: AppLocalization.localized("tts.speed_label"), speedPreset.label)
                )
                .accessibilityHint(AppLocalization.localized("tts.speed_hint"))

                Button(action: onStop) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("ttsStopButton")
                .accessibilityLabel(AppLocalization.localized("tts.stop"))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Playing") {
    VStack {
        Spacer()
        SpeechPlayerBarView(
            title: "SwiftUI 6.0 Brings Revolutionary New Features",
            playbackState: .playing,
            progress: 0.35,
            speedPreset: .normal,
            onPlayPause: {},
            onStop: {},
            onSpeedTap: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Paused - Fast") {
    VStack {
        Spacer()
        SpeechPlayerBarView(
            title: "Article Title Here",
            playbackState: .paused,
            progress: 0.7,
            speedPreset: .fast,
            onPlayPause: {},
            onStop: {},
            onSpeedTap: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
