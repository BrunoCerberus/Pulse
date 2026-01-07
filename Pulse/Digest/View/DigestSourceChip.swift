import SwiftUI

/// Compact chip for selecting digest source in horizontal scroll
struct DigestSourceChip: View {
    let source: DigestSource
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: source.icon)
                    .font(.system(size: IconSize.sm))

                Text(source.displayName)
                    .font(Typography.labelMedium)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected
                    ? Color.Accent.primary
                    : Color(.systemBackground).opacity(0.8)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected
                            ? Color.clear
                            : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.95)
        .accessibilityLabel(source.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.sm) {
            DigestSourceChip(source: .bookmarks, isSelected: true, onTap: {})
            DigestSourceChip(source: .readingHistory, isSelected: false, onTap: {})
            DigestSourceChip(source: .freshNews, isSelected: false, onTap: {})
        }
        .padding(.horizontal, Spacing.md)
    }
    .padding(.vertical)
    .background(.ultraThinMaterial)
}
