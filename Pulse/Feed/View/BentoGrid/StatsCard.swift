import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var articlesLabel: String {
        AppLocalization.shared.localized("digest.articles_label")
    }

    static var topicsLabel: String {
        AppLocalization.shared.localized("digest.topics_label")
    }

    static var timeSpanLabel: String {
        AppLocalization.shared.localized("digest.time_span")
    }
}

// MARK: - StatsCard

struct StatsCard: View {
    let articleCount: Int
    let topicsCount: Int
    var minHeight: CGFloat?

    @State private var animatedArticleCount: Int = 0
    @State private var animatedTopicsCount: Int = 0
    @State private var animationTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header

            VStack(alignment: .leading, spacing: Spacing.xs) {
                statRow(
                    value: animatedArticleCount,
                    label: Constants.articlesLabel,
                    icon: "doc.text"
                )

                statRow(
                    value: animatedTopicsCount,
                    label: Constants.topicsLabel,
                    icon: "tag"
                )

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: IconSize.xs))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    Text(Constants.timeSpanLabel)
                        .font(Typography.captionMedium)
                        .foregroundStyle(.secondary)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: AppLocalization.shared.localized("digest.stats_accessibility"), articleCount, topicsCount))
        .onAppear {
            animationTask?.cancel()
            animationTask = Task {
                await animateCounters()
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
            Image(systemName: "chart.bar.fill")
                .font(.system(size: IconSize.sm))
                .foregroundStyle(Color.Accent.gradient)
                .accessibilityHidden(true)

            Text(AppLocalization.shared.localized("digest.stats_title"))
                .font(Typography.labelMedium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Stat Row

    private func statRow(value: Int, label: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: IconSize.xs))
                .foregroundStyle(Color.Accent.primary)
                .accessibilityHidden(true)

            Text("\(value)")
                .font(Typography.titleSmall)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text(label)
                .font(Typography.captionMedium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Animation

    @MainActor
    private func animateCounters() async {
        if reduceMotion {
            animatedArticleCount = articleCount
            animatedTopicsCount = topicsCount
            return
        }

        // Animate article count
        await animateCounter(
            from: 0,
            to: articleCount,
            duration: 0.6,
            update: { animatedArticleCount = $0 }
        )

        // Animate topics count (runs after article count completes)
        await animateCounter(
            from: 0,
            to: topicsCount,
            duration: 0.5,
            update: { animatedTopicsCount = $0 }
        )
    }

    @MainActor
    private func animateCounter(
        from start: Int,
        to end: Int,
        duration: Double,
        update: (Int) -> Void
    ) async {
        let steps = min(end - start, 20)
        guard steps > 0 else {
            update(end)
            return
        }

        let stepDuration = duration / Double(steps)
        let stepNanoseconds = UInt64(stepDuration * 1_000_000_000)

        for step in 0 ... steps {
            guard !Task.isCancelled else { return }

            let progress = Double(step) / Double(steps)
            let value = start + Int(Double(end - start) * progress)
            withAnimation(.easeOut(duration: stepDuration)) {
                update(value)
            }

            if step < steps {
                try? await Task.sleep(nanoseconds: stepNanoseconds)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StatsCard(articleCount: 5, topicsCount: 3)
        .padding()
        .background(LinearGradient.subtleBackground)
        .preferredColorScheme(.dark)
}
