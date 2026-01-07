import SwiftUI

/// Card component for selecting a digest content source
struct DigestSourceCard: View {
    let source: DigestSource
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(
                style: isSelected ? .regular : .thin,
                shadowStyle: isSelected ? .elevated : .subtle,
                padding: Spacing.lg
            ) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.Accent.gradient : LinearGradient(
                                colors: [Color.secondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)

                        Image(systemName: source.icon)
                            .font(.system(size: IconSize.md))
                            .foregroundStyle(isSelected ? .white : .secondary)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(source.displayName)
                            .font(Typography.labelLarge)
                            .foregroundStyle(isSelected ? Color.Accent.primary : .primary)

                        Text(source.description)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.lg))
                            .foregroundStyle(Color.Accent.primary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.98)
        .padding(.horizontal, Spacing.lg)
        .accessibilityLabel("\(source.displayName). \(source.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        DigestSourceCard(
            source: .bookmarks,
            isSelected: true,
            onTap: {}
        )

        DigestSourceCard(
            source: .readingHistory,
            isSelected: false,
            onTap: {}
        )

        DigestSourceCard(
            source: .freshNews,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(LinearGradient.subtleBackground)
}
