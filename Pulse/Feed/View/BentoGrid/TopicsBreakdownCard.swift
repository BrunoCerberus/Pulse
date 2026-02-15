import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let maxBarWidth: CGFloat = 60
    static let barHeight: CGFloat = 6
}

// MARK: - TopicsBreakdownCard

struct TopicsBreakdownCard: View {
    let breakdown: [(NewsCategory, Int)]
    var minHeight: CGFloat?

    @State private var animatedProgress: [String: CGFloat] = [:]
    @State private var animationTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maxCount: Int {
        breakdown.map(\.1).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(breakdown.prefix(4), id: \.0.id) { category, count in
                    topicRow(category: category, count: count)
                }
            }

            if minHeight != nil {
                Spacer(minLength: 0)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
        .depthShadow(.medium)
        .onAppear {
            animationTask?.cancel()
            animationTask = Task {
                await animateBars()
            }
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "tag.fill")
                .font(.system(size: IconSize.sm))
                .foregroundStyle(Color.Accent.gradient)
                .accessibilityHidden(true)

            Text("Topics")
                .font(Typography.labelMedium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Topic Row

    private func topicRow(category: NewsCategory, count: Int) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(category.displayName)
                .font(Typography.captionMedium)
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geometry in
                let progress = animatedProgress[category.id] ?? 0
                let targetWidth = (CGFloat(count) / CGFloat(maxCount)) * min(geometry.size.width, Constants.maxBarWidth)

                RoundedRectangle(cornerRadius: Constants.barHeight / 2)
                    .fill(category.color.gradient)
                    .frame(width: targetWidth * progress, height: Constants.barHeight)
            }
            .frame(height: Constants.barHeight)
        }
    }

    // MARK: - Animation

    @MainActor
    private func animateBars() async {
        // Initialize all progress to 0
        for (category, _) in breakdown {
            animatedProgress[category.id] = 0
        }

        if reduceMotion {
            for (category, _) in breakdown {
                animatedProgress[category.id] = 1
            }
            return
        }

        // Staggered animation for each bar
        for (index, (category, _)) in breakdown.prefix(4).enumerated() {
            guard !Task.isCancelled else { return }

            if index > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress[category.id] = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TopicsBreakdownCard(
        breakdown: [
            (.technology, 3),
            (.business, 2),
            (.world, 1),
        ]
    )
    .padding()
    .background(LinearGradient.subtleBackground)
    .preferredColorScheme(.dark)
}
