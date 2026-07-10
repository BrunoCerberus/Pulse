import EntropyCore
import SwiftUI

/// Compact call-to-action card embedded in `HomeView`, next to the For You
/// carousel. Builds an on-demand, personalized audio playlist of unread
/// articles via the global playback queue.
struct SmartBriefingCardView: View {
    enum Constants {
        static var sectionTitle: String {
            AppLocalization.localized("smart_briefing.section_title")
        }

        static var headline: String {
            AppLocalization.localized("smart_briefing.headline")
        }

        static var buildButton: String {
            AppLocalization.localized("smart_briefing.build_button")
        }

        static var startFreshButton: String {
            AppLocalization.localized("smart_briefing.start_fresh_button")
        }

        static var firstRunCaption: String {
            AppLocalization.localized("smart_briefing.first_run_caption")
        }

        static func lastServedCaption(_ relativeDate: String) -> String {
            String(format: AppLocalization.localized("smart_briefing.last_served_caption"), relativeDate)
        }
    }

    let viewState: SmartBriefingViewState
    let onBuildBriefingTapped: () -> Void
    let onStartFreshTapped: () -> Void

    private var caption: String {
        if let statusMessage = viewState.statusMessage {
            return statusMessage
        }
        guard let lastServedAt = viewState.lastServedAt else {
            return Constants.firstRunCaption
        }
        let relative = Self.relativeFormatter.localizedString(for: lastServedAt, relativeTo: .now)
        return Constants.lastServedCaption(relative)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Constants.headline)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)

            Text(caption)
                .font(Typography.labelMedium)
                .foregroundStyle(.tertiary)

            HStack(spacing: Spacing.sm) {
                Button {
                    HapticManager.shared.buttonPress()
                    onBuildBriefingTapped()
                } label: {
                    if viewState.isBuilding {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(Constants.buildButton, systemImage: "headphones")
                            .font(Typography.labelLarge)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(viewState.isBuilding)
                .accessibilityIdentifier("smartBriefingBuildButton")
                .accessibilityLabel(Constants.buildButton)

                if viewState.lastServedAt != nil {
                    Button {
                        HapticManager.shared.tap()
                        onStartFreshTapped()
                    } label: {
                        Text(Constants.startFreshButton)
                            .font(Typography.labelMedium)
                    }
                    .buttonStyle(.glass)
                    .disabled(viewState.isBuilding)
                    .accessibilityIdentifier("smartBriefingStartFreshButton")
                }
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

// MARK: - Preview

#Preview("Fresh") {
    SmartBriefingCardView(
        viewState: .initial,
        onBuildBriefingTapped: {},
        onStartFreshTapped: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Recently Served") {
    SmartBriefingCardView(
        viewState: SmartBriefingViewState(
            isVisible: true,
            isBuilding: false,
            lastServedAt: .now.addingTimeInterval(-3 * 3600),
            statusMessage: nil
        ),
        onBuildBriefingTapped: {},
        onStartFreshTapped: {}
    )
    .preferredColorScheme(.dark)
}
