import EntropyCore
import SwiftUI

struct SpeechPlayerBarView: View {
    private enum Constants {
        static var progress: String {
            AppLocalization.localized("tts.progress")
        }

        static var progressValue: String {
            AppLocalization.localized("tts.progress_value")
        }

        static var pause: String {
            AppLocalization.localized("tts.pause")
        }

        static var play: String {
            AppLocalization.localized("tts.play")
        }

        static var listening: String {
            AppLocalization.localized("tts.listening")
        }

        static var speedLabel: String {
            AppLocalization.localized("tts.speed_label")
        }

        static var speedHint: String {
            AppLocalization.localized("tts.speed_hint")
        }

        static var stop: String {
            AppLocalization.localized("tts.stop")
        }
    }

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
                .accessibilityLabel(Constants.progress)
                .accessibilityValue(
                    String(format: Constants.progressValue, Int(progress * 100))
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
                        ? Constants.pause
                        : Constants.play
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(Constants.listening)
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
                    String(format: Constants.speedLabel, speedPreset.label)
                )
                .accessibilityHint(Constants.speedHint)

                Button(action: onStop) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("ttsStopButton")
                .accessibilityLabel(Constants.stop)
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
