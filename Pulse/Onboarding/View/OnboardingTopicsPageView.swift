import EntropyCore
import SwiftUI

struct OnboardingTopicsPageView: View {
    let selectedTopics: Set<NewsCategory>
    let onToggle: (NewsCategory) -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(NewsCategory.allCases) { category in
                        TopicCell(
                            category: category,
                            isSelected: selectedTopics.contains(category),
                            onTap: {
                                HapticManager.shared.selectionChanged()
                                onToggle(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(OnboardingPage.chooseTopics.iconColor.opacity(0.15))
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(OnboardingPage.chooseTopics.iconColor.gradient)
                    .frame(width: 72, height: 72)

                Image(systemName: OnboardingPage.chooseTopics.icon)
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            .glowEffect(color: OnboardingPage.chooseTopics.iconColor, radius: 14)

            Text(OnboardingPage.chooseTopics.title)
                .font(Typography.headlineLarge)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(OnboardingPage.chooseTopics.subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.top, Spacing.md)
    }
}

// MARK: - Topic Cell

private struct TopicCell: View {
    let category: NewsCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : category.color)

                Text(category.displayName)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .pressEffect()
        .accessibilityLabel(category.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(
            isSelected
                ? AppLocalization.localized("topic_editor.unfollow_hint")
                : AppLocalization.localized("topic_editor.follow_hint")
        )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
            .fill(
                isSelected
                    ? AnyShapeStyle(category.color.gradient)
                    : AnyShapeStyle(Color.white.opacity(0.08))
            )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
            .stroke(
                isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.15),
                lineWidth: 1
            )
    }
}

#Preview("Empty") {
    ZStack {
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OnboardingTopicsPageView(selectedTopics: [], onToggle: { _ in })
    }
    .preferredColorScheme(.dark)
}

#Preview("Some Selected") {
    ZStack {
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OnboardingTopicsPageView(
            selectedTopics: [.technology, .science, .business],
            onToggle: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
