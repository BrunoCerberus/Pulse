@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class DigestViewSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    // Custom device config matching CI's iPhone Air simulator
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // Fixed date for snapshot stability
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023 00:00:00 UTC

    override func setUp() {
        super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(DigestService.self, instance: MockDigestService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
    }

    // MARK: - Onboarding State

    func testDigestViewOnboarding() {
        let view = NavigationStack {
            DigestOnboardingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Source Selection with Articles

    func testDigestViewSourceSelection() {
        let view = NavigationStack {
            DigestSourceSelectionPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Loading Articles State

    func testDigestViewLoadingArticles() {
        let view = NavigationStack {
            DigestLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Generating State

    func testDigestViewGenerating() {
        let view = NavigationStack {
            DigestGeneratingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Result State

    func testDigestViewResult() {
        let view = NavigationStack {
            DigestResultPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Empty State

    func testDigestViewEmpty() {
        let view = NavigationStack {
            DigestEmptyPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - No Topics Error State

    func testDigestViewNoTopics() {
        let view = NavigationStack {
            DigestNoTopicsPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Error State

    func testDigestViewError() {
        let view = NavigationStack {
            DigestErrorPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Model Loading Progress

    func testDigestViewModelLoading() {
        let view = NavigationStack {
            DigestModelLoadingPreview()
        }
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Preview Helpers for State Testing

private struct DigestOnboardingPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Hero section
                GlassCard(style: .regular, shadowStyle: .elevated, padding: Spacing.xl) {
                    VStack(spacing: Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(Color.Accent.gradient)
                                .frame(width: 100, height: 100)

                            Image(systemName: "sparkles")
                                .font(.system(size: IconSize.xxl))
                                .foregroundStyle(.white)
                        }
                        .glowEffect(color: Color.Accent.primary, radius: 16)

                        Text("AI Digest")
                            .font(Typography.displaySmall)

                        Text("Generate personalized summaries from your news")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                // Source selection
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Select a source")
                        .font(Typography.titleSmall)
                        .padding(.horizontal, Spacing.lg)

                    ForEach(DigestSource.allCases) { source in
                        DigestSourceCard(
                            source: source,
                            isSelected: false,
                            onTap: {}
                        )
                    }
                }

                // Model status
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(.secondary)
                    Text("Loading AI model...")
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestSourceSelectionPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private var mockArticles: [Article] {
        [
            Article(
                id: "1",
                title: "AI Revolution: How Machine Learning is Transforming Industries",
                description: "From healthcare to finance, AI is reshaping the business landscape",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "2",
                title: "Apple Announces New MacBook Pro with M4 Chip",
                description: "The latest MacBook Pro features unprecedented performance",
                source: ArticleSource(id: "theverge", name: "The Verge"),
                url: "https://example.com/2",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            ),
            Article(
                id: "3",
                title: "Swift 6 Brings Major Language Improvements",
                description: "New concurrency features and performance optimizations",
                source: ArticleSource(id: "hackingwithswift", name: "Hacking with Swift"),
                url: "https://example.com/3",
                imageURL: nil,
                publishedAt: fixedDate,
                category: .technology
            ),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .bookmarks)

                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("5 articles available")
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)

                    ForEach(mockArticles.prefix(3)) { article in
                        GlassCard(style: .thin, padding: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(article.title)
                                    .font(Typography.bodyMedium)
                                    .lineLimit(2)
                                Text(article.source.name)
                                    .font(Typography.captionLarge)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    Text("+ 2 more articles")
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)

                    Button {} label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                            Text("Generate Digest")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.Accent.gradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestLoadingPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .freshNews)

                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading articles...")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.5
                }
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestGeneratingPreview: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                ForEach(0 ..< 3, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.Accent.primary)
                        .offset(
                            x: CGFloat(index * 20 - 20),
                            y: CGFloat(index * 15 - 15)
                        )
                        .opacity(0.6)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary)
            }

            Text("Generating your digest...")
                .font(Typography.titleMedium)

            GlassCard(style: .thin, padding: Spacing.md) {
                Text("Here's your personalized news digest based on the articles you've been reading...")
                    .font(Typography.bodyMedium)
                    .lineLimit(10)
            }
            .padding(.horizontal, Spacing.lg)

            Button {} label: {
                Text("Cancel")
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.Semantic.warning)
            }

            Spacer()
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestResultPreview: View {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                GlassCard(style: .regular, padding: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("AI Digest")
                                .font(Typography.titleSmall)
                            Text("From 5 articles")
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(fixedDate.formatted(date: .abbreviated, time: .shortened))
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                GlassCard(style: .thin, padding: Spacing.lg) {
                    Text("""
                    Here's your personalized news digest based on the articles you've been reading.

                    **Key Headlines:**
                    The technology sector continues to see significant developments, with major announcements in AI and machine learning. Market trends indicate growing investor confidence in sustainable technologies.

                    **What's Trending:**
                    Health and wellness topics remain popular, with new research highlighting the importance of work-life balance. Sports enthusiasts are following championship updates closely.

                    **Your Interests:**
                    Based on your reading patterns, you might be interested in upcoming developments in your favorite categories.

                    Stay informed and have a great day!
                    """)
                    .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.md) {
                    Button {} label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("New Digest")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(Color.Accent.primary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }

                    Button {} label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestEmptyPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .bookmarks)

                GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: IconSize.xxl))
                            .foregroundStyle(.secondary)

                        Text("No Articles")
                            .font(Typography.titleMedium)

                        Text("No articles available in your bookmarks. Save some articles to generate a digest.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestNoTopicsPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .freshNews)

                GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: IconSize.xxl))
                            .foregroundStyle(Color.Accent.primary)

                        Text("No Topics Selected")
                            .font(Typography.titleMedium)

                        Text("You haven't selected any topics yet. Configure your interests in Settings to get fresh news.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {} label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Configure Topics")
                            }
                            .font(Typography.labelLarge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Accent.primary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestErrorPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .readingHistory)

                GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: IconSize.xxl))
                            .foregroundStyle(Color.Semantic.warning)

                        Text("Error")
                            .font(Typography.titleMedium)

                        Text("Failed to generate digest. Please check your connection and try again.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {} label: {
                            Text("Try Again")
                                .font(Typography.labelLarge)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.Accent.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct DigestModelLoadingPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow(selectedSource: .bookmarks)

                VStack(spacing: Spacing.xs) {
                    ProgressView(value: 0.65)
                        .tint(Color.Accent.primary)
                    Text("Loading AI model... 65%")
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)

                GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "cpu")
                            .font(.system(size: IconSize.xxl))
                            .foregroundStyle(Color.Accent.primary)

                        Text("Preparing AI")
                            .font(Typography.titleMedium)

                        Text("The AI model is loading. This may take a moment on first launch.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle("AI Digest")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Shared Helper

private func sourceChipsRow(selectedSource: DigestSource?) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.sm) {
            ForEach(DigestSource.allCases) { source in
                DigestSourceChip(
                    source: source,
                    isSelected: source == selectedSource,
                    onTap: {}
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    .padding(.vertical, Spacing.sm)
    .background(.ultraThinMaterial)
}
