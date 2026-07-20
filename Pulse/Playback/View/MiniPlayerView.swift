import EntropyCore
import SwiftUI

/// Persistent mini player rendered above the tab bar / split view for as long
/// as the playback queue is active. Replaces the old per-article
/// `SpeechPlayerBarView`; playback survives navigation, so this is the one
/// always-reachable surface for transport controls.
///
/// Tapping the title area expands the full queue sheet.
struct MiniPlayerView: View {
    @ObservedObject var viewModel: PlaybackViewModel

    var body: some View {
        // The animation lives here, not in `CoordinatorView`: visibility
        // changes re-render only this view (it is the `@ObservedObject`
        // observer), so an ancestor `.animation(value:)` would never see them.
        ZStack {
            if viewModel.viewState.isVisible {
                playerBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .sheet(isPresented: queueSheetBinding) {
                        PlaybackQueueSheet(viewModel: viewModel)
                    }
                    .onAppear {
                        // The bar appears with playback already running, so the
                        // `onChange` below never fires for the initial state.
                        guard viewModel.viewState.isPlaying else { return }
                        AccessibilityNotification.Announcement(Constants.playingAnnouncement).post()
                    }
                    .onChange(of: viewModel.viewState.isPlaying) { _, isPlaying in
                        let announcement = isPlaying ? Constants.playingAnnouncement : Constants.pausedAnnouncement
                        AccessibilityNotification.Announcement(announcement).post()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.viewState.isVisible)
    }

    private var playerBar: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 0) {
                ProgressView(value: min(max(viewModel.viewState.itemProgress, 0), 1))
                    .tint(Color.Accent.gradient)
                    .accessibilityLabel(Constants.progress)
                    .accessibilityValue(
                        String(format: Constants.progressValue, Int(viewModel.viewState.itemProgress * 100)),
                    )

                HStack(spacing: Spacing.md) {
                    Button {
                        viewModel.handle(event: .onPlayPauseTapped)
                    } label: {
                        Image(systemName: viewModel.viewState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .frame(width: 32, height: 32)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("ttsPlayPauseButton")
                    .accessibilityLabel(viewModel.viewState.isPlaying ? Constants.pause : Constants.play)

                    titleArea

                    Spacer(minLength: Spacing.xs)

                    if viewModel.viewState.hasNext {
                        Button {
                            viewModel.handle(event: .onNextTapped)
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                                .frame(width: 28, height: 28)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("ttsNextButton")
                        .accessibilityLabel(Constants.next)
                    }

                    Button {
                        viewModel.handle(event: .onSpeedTapped)
                    } label: {
                        Text(viewModel.viewState.speedLabel)
                            .font(Typography.labelMedium)
                            .monospacedDigit()
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .glassEffect(
                                .regular.interactive(),
                                in: .rect(cornerRadius: CornerRadius.sm),
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("ttsSpeedButton")
                    .accessibilityLabel(String(format: Constants.speedLabel, viewModel.viewState.speedLabel))
                    .accessibilityHint(Constants.speedHint)

                    Button {
                        viewModel.handle(event: .onStopTapped)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("ttsStopButton")
                    .accessibilityLabel(Constants.stop)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.md))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("speechPlayerBar")
    }

    private var titleArea: some View {
        Button {
            viewModel.handle(event: .onExpandTapped)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(Constants.listening)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let position = viewModel.viewState.queuePositionLabel {
                        Text(position)
                            .font(Typography.captionLarge)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Text(viewModel.viewState.title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("miniPlayerExpandButton")
        .accessibilityLabel(viewModel.viewState.title)
        .accessibilityHint(Constants.expandHint)
    }

    private var queueSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.viewState.isQueueSheetPresented },
            set: { isPresented in
                if !isPresented {
                    viewModel.handle(event: .onQueueSheetDismissed)
                }
            },
        )
    }
}
