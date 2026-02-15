import EntropyCore
import SwiftUI

// MARK: - Glass Category Chip

struct GlassCategoryChip: View {
    let category: NewsCategory
    var style: ChipStyle
    var isSelected: Bool
    var showIcon: Bool

    @Environment(\.colorScheme) private var colorScheme

    enum ChipStyle {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small: return Typography.labelSmall
            case .medium: return Typography.labelMedium
            case .large: return Typography.labelLarge
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return Spacing.xs
            case .medium: return Spacing.sm
            case .large: return Spacing.md
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return Spacing.xxs
            case .medium: return Spacing.xs
            case .large: return Spacing.sm
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return IconSize.xs
            case .medium: return IconSize.sm
            case .large: return IconSize.md
            }
        }
    }

    init(
        category: NewsCategory,
        style: ChipStyle = .medium,
        isSelected: Bool = false,
        showIcon: Bool = false
    ) {
        self.category = category
        self.style = style
        self.isSelected = isSelected
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if showIcon {
                Image(systemName: category.icon)
                    .font(.system(size: style.iconSize))
            }

            Text(category.displayName)
                .font(style.font)
        }
        .foregroundStyle(isSelected ? .white : category.color)
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .background {
            if isSelected {
                Capsule()
                    .fill(category.color)
            } else {
                Capsule()
                    .fill(category.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(category.color.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
        .glowEffect(color: isSelected ? category.color : .clear, radius: 6)
    }
}

// MARK: - Glass Category Button

struct GlassCategoryButton: View {
    let category: NewsCategory
    var isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        category: NewsCategory,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.selectionChanged()
            action()
        } label: {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: category.icon)
                        .font(.system(size: IconSize.lg))
                        .foregroundStyle(isSelected ? .white : category.color)
                }
                .glowEffect(color: isSelected ? category.color : .clear, radius: 8)

                Text(category.displayName)
                    .font(Typography.captionMedium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 90)
            .padding(Spacing.sm)
            .glassBackground(
                style: isSelected ? .regular : .ultraThin,
                cornerRadius: CornerRadius.lg,
                showBorder: true
            )
        }
        .pressEffect(scale: 0.95)
        .accessibilityLabel("\(category.displayName) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Topic Chip (For Category Tabs)

struct GlassTopicChip: View {
    let topic: String
    var isSelected: Bool
    var color: Color
    let action: () -> Void

    init(
        topic: String,
        isSelected: Bool = false,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.topic = topic
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.selectionChanged()
            action()
        } label: {
            Text(topic)
                .font(Typography.labelMedium)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(color)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                }
                .glowEffect(color: isSelected ? color : .clear, radius: 6)
        }
        .pressEffect(scale: 0.95)
        .accessibilityLabel(topic)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Category Chips") {
    ZStack {
        LinearGradient.meshFallback
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                GlassCategoryChip(category: .technology, style: .small)
                GlassCategoryChip(category: .business, style: .medium)
                GlassCategoryChip(category: .science, style: .large, showIcon: true)
            }

            HStack(spacing: Spacing.sm) {
                GlassCategoryChip(category: .technology, style: .medium, isSelected: true)
                GlassCategoryChip(category: .health, style: .medium, isSelected: false)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        GlassCategoryButton(
                            category: category,
                            isSelected: category == .technology
                        ) {}
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: Spacing.sm) {
                GlassTopicChip(topic: "AI", isSelected: true, color: .purple) {}
                GlassTopicChip(topic: "Startups", isSelected: false, color: .blue) {}
                GlassTopicChip(topic: "Gaming", isSelected: false, color: .green) {}
            }
        }
    }
    .preferredColorScheme(.dark)
}
