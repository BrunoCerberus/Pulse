import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("feed.empty.title")
    }

    static var message: String {
        AppLocalization.localized("feed.empty.message")
    }

    static var startReading: String {
        AppLocalization.localized("feed.start_reading")
    }
}

// MARK: - FeedEmptyStateView

struct FeedEmptyStateView: View {
    var body: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                iconView

                Text(Constants.title)
                    .font(Typography.titleMedium)
                    .accessibilityAddTraits(.isHeader)

                Text(Constants.message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.Accent.primary.opacity(0.1))
                .frame(width: 80, height: 80)

            Image(systemName: "text.document")
                .font(.system(size: IconSize.xxl))
                .foregroundStyle(Color.Accent.primary.opacity(0.6))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    FeedEmptyStateView()
        .padding()
        .preferredColorScheme(.dark)
}
