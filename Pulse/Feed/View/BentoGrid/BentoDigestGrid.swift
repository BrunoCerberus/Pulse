import SwiftUI

// MARK: - Constants

private enum Constants {
    static let gridSpacing: CGFloat = 12
}

// MARK: - BentoDigestGrid

struct BentoDigestGrid: View {
    let digest: DigestViewItem
    let sourceArticles: [FeedSourceArticle]
    let onArticleTapped: (FeedSourceArticle) -> Void

    @State private var showKeyInsight = false
    @State private var showStats = false
    @State private var showTopics = false
    @State private var showSections: Set<String> = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sections: [DigestSection] {
        digest.parseSections(with: sourceArticles)
    }

    private var topicsBreakdown: [(NewsCategory, Int)] {
        digest.computeTopicsBreakdown(from: sourceArticles)
    }

    var body: some View {
        VStack(spacing: Constants.gridSpacing) {
            // Key Insight - full width
            keyInsightView

            // Stats and Topics side by side
            statsAndTopicsRow

            // Content sections (full width)
            ForEach(sections) { section in
                contentSectionView(section)
            }
        }
        .onAppear {
            triggerStaggeredAnimations()
        }
    }

    // MARK: - Stats and Topics Row

    private var statsAndTopicsRow: some View {
        HStack(alignment: .top, spacing: Constants.gridSpacing) {
            StatsCard(
                articleCount: digest.articleCount,
                topicsCount: topicsBreakdown.count
            )
            .frame(maxWidth: .infinity)
            .opacity(showStats ? 1 : 0)
            .offset(y: showStats ? 0 : 20)
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: showStats)

            if !topicsBreakdown.isEmpty {
                TopicsBreakdownCard(breakdown: topicsBreakdown)
                    .frame(maxWidth: .infinity)
                    .opacity(showTopics ? 1 : 0)
                    .offset(y: showTopics ? 0 : 20)
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: showTopics)
            }
        }
    }

    // MARK: - Key Insight View

    private var keyInsightView: some View {
        KeyInsightCard(
            insight: digest.keyInsight,
            relatedArticles: Array(sourceArticles.prefix(2)),
            onArticleTapped: onArticleTapped
        )
        .opacity(showKeyInsight ? 1 : 0)
        .scaleEffect(showKeyInsight ? 1 : 0.95)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: showKeyInsight)
    }

    // MARK: - Content Section View

    private func contentSectionView(_ section: DigestSection) -> some View {
        let isVisible = showSections.contains(section.id)

        return ContentSectionCard(
            section: section,
            onArticleTapped: onArticleTapped
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
    }

    // MARK: - Staggered Animations

    private func triggerStaggeredAnimations() {
        if reduceMotion {
            // Show everything immediately for reduced motion
            showKeyInsight = true
            showStats = true
            showTopics = true
            for section in sections {
                showSections.insert(section.id)
            }
            return
        }

        // Staggered reveal sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showKeyInsight = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showStats = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showTopics = true
        }

        // Stagger content sections
        for (index, section) in sections.enumerated() {
            let delay = 0.35 + Double(index) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                showSections.insert(section.id)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let previewSummary = """
    Today's reading focused on technology and business developments. AI advancements dominated the tech news \
    with several major announcements from leading companies.

    The technology sector saw significant movement with new product launches and strategic partnerships \
    being announced across the industry.

    Business markets responded positively to the tech developments, with stock prices reflecting investor \
    optimism about the future of AI-driven products.
    """

    let mockDigest = DigestViewItem(
        from: DailyDigest(
            id: "preview",
            summary: previewSummary,
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
    )

    return ScrollView {
        BentoDigestGrid(
            digest: mockDigest,
            sourceArticles: Article.mockArticles.map { FeedSourceArticle(from: $0) },
            onArticleTapped: { _ in }
        )
        .padding(.horizontal, Spacing.md)
    }
    .background(LinearGradient.subtleBackground)
}
