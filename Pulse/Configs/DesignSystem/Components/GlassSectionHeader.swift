import EntropyCore
import SwiftUI

// MARK: - Glass Section Header

struct GlassSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var style: GlassStyle

    @Environment(\.colorScheme) private var colorScheme

    init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        style: GlassStyle = .ultraThin,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.style = style
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.titleMedium)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button {
                    HapticManager.shared.tap()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(Typography.labelMedium)
                        .foregroundStyle(Color.Accent.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.material)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.Border.adaptive(for: colorScheme)),
            alignment: .bottom
        )
    }
}

// MARK: - Sticky Section Header

struct StickySectionHeader: View {
    let title: String
    var showBackground: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String, showBackground: Bool = true) {
        self.title = title
        self.showBackground = showBackground
    }

    var body: some View {
        Text(title)
            .font(Typography.titleSmall)
            .foregroundStyle(.primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(showBackground ? AnyShapeStyle(GlassStyle.ultraThin.material) : AnyShapeStyle(.clear))
    }
}

// MARK: - Previews

#Preview("Section Headers") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        VStack(spacing: 0) {
            GlassSectionHeader("Breaking News")

            GlassSectionHeader(
                "Top Stories",
                subtitle: "Updated 5 minutes ago",
                actionTitle: "See All"
            ) {
                Logger.shared.debug("See all tapped", category: "UI")
            }

            StickySectionHeader("Technology")

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
