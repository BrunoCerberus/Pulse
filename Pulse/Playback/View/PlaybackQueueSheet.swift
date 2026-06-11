import EntropyCore
import SwiftUI

/// Expanded queue view presented from the mini player.
///
/// Shows every item in the playback queue with the current one highlighted;
/// tapping a row jumps playback to that item. Speed and stop controls mirror
/// the mini player for reachability.
struct PlaybackQueueSheet: View {
    @ObservedObject var viewModel: PlaybackViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.viewState.queueItems) { item in
                queueRow(item)
            }
            .listStyle(.plain)
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.handle(event: .onSpeedTapped)
                    } label: {
                        Text(viewModel.viewState.speedLabel)
                            .font(Typography.labelMedium)
                            .monospacedDigit()
                    }
                    .accessibilityIdentifier("queueSheetSpeedButton")
                    .accessibilityLabel(String(format: Constants.speedLabel, viewModel.viewState.speedLabel))
                    .accessibilityHint(Constants.speedHint)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handle(event: .onStopTapped)
                    } label: {
                        Label(Constants.stop, systemImage: "stop.fill")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityIdentifier("queueSheetStopButton")
                    .accessibilityLabel(Constants.stop)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func queueRow(_ item: PlaybackQueueItemViewItem) -> some View {
        Button {
            viewModel.handle(event: .onQueueItemTapped(itemID: item.id))
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: rowIcon(for: item))
                    .font(.system(size: 16))
                    .foregroundStyle(
                        item.isCurrent
                            ? AnyShapeStyle(Color.Accent.gradient)
                            : AnyShapeStyle(.secondary)
                    )
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(item.isCurrent ? Typography.labelLarge : Typography.labelMedium)
                        .foregroundStyle(item.isCurrent ? .primary : .secondary)
                        .lineLimit(2)

                    Text(item.sourceName)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                if item.isCurrent {
                    Image(systemName: viewModel.viewState.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.Accent.gradient)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.isCurrent ? Constants.currentItemHint : Constants.jumpHint)
    }

    private func rowIcon(for item: PlaybackQueueItemViewItem) -> String {
        item.isDigest ? "sparkles" : "doc.text"
    }
}
