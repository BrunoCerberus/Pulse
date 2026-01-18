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

    @State private var showStats = false
    @State private var showTopics = false
    @State private var showSections: Set<String> = []
    @State private var animationTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sections: [DigestSection] {
        digest.parseSections(with: sourceArticles)
    }

    private var topicsBreakdown: [(NewsCategory, Int)] {
        digest.computeTopicsBreakdown(from: sourceArticles)
    }

    var body: some View {
        VStack(spacing: Constants.gridSpacing) {
            // Stats and Topics side by side
            statsAndTopicsRow

            // Content sections (full width) - each category with its summary
            ForEach(sections) { section in
                contentSectionView(section)
            }
        }
        .onAppear {
            animationTask?.cancel()
            animationTask = Task {
                await triggerStaggeredAnimations()
            }
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
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

    @MainActor
    private func triggerStaggeredAnimations() async {
        if reduceMotion {
            // Show everything immediately for reduced motion
            showStats = true
            showTopics = true
            for section in sections {
                showSections.insert(section.id)
            }
            return
        }

        // Staggered reveal sequence
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        guard !Task.isCancelled else { return }
        showStats = true

        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second (total 0.15)
        guard !Task.isCancelled else { return }
        showTopics = true

        // Stagger content sections
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second (total 0.25)

        for section in sections {
            guard !Task.isCancelled else { return }
            showSections.insert(section.id)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second between each
        }
    }
}

// MARK: - Preview

#Preview {
    let previewSummary = """
    **Technology** AI advancements dominated the tech news with several major announcements from leading companies.

    **Business** Markets responded positively to the tech developments, with stock prices reflecting investor optimism.

    **World** International news covered climate agreements and diplomatic developments across multiple regions.
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
