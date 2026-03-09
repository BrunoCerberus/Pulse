import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var storySoFar: String {
        AppLocalization.localized("story_threads.story_so_far")
    }

    static var followStory: String {
        AppLocalization.localized("story_threads.follow")
    }

    static var unfollowStory: String {
        AppLocalization.localized("story_threads.unfollow")
    }

    static var articlesInThread: String {
        AppLocalization.localized("story_threads.articles_in_thread")
    }

    static var generateSummary: String {
        AppLocalization.localized("story_threads.generate_summary")
    }

    static var generating: String {
        AppLocalization.localized("summarization.generating")
    }
}

// MARK: - StoryThreadDetailView

struct StoryThreadDetailView: View {
    let thread: StoryThreadItem
    let articles: [Article]
    let serviceLocator: ServiceLocator
    let onArticleTapped: ((Article) -> Void)?

    @State private var isFollowing: Bool
    @State private var summary: String
    @State private var isPremium = false
    @State private var isPaywallPresented = false
    @State private var isGeneratingSummary = false
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        thread: StoryThreadItem,
        articles: [Article] = [],
        serviceLocator: ServiceLocator,
        onArticleTapped: ((Article) -> Void)? = nil
    ) {
        self.thread = thread
        self.articles = articles
        self.serviceLocator = serviceLocator
        self.onArticleTapped = onArticleTapped
        _isFollowing = State(initialValue: thread.isFollowing)
        _summary = State(initialValue: thread.summary)
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                threadHeader
                summarySection
                articlesSection
            }
            .padding(Spacing.md)
        }
        .background(LinearGradient.subtleBackground.ignoresSafeArea())
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                followButton
            }
        }
        .onAppear {
            initializeSubscriptionStatus()
        }
        .onReceive(subscriptionStatusPublisher) { newStatus in
            isPremium = newStatus
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
        .accessibilityIdentifier("storyThreadDetailView")
    }

    // MARK: - Header

    private var threadHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(thread.category.capitalized)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(.tertiary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(
                    String(format: AppLocalization.localized("story_threads.article_count"), thread.articleCount)
                )
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)

                Circle()
                    .fill(.tertiary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(thread.lastUpdated)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label(Constants.storySoFar, systemImage: "sparkles")
                    .font(Typography.titleSmall)
                    .bold()
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if isPremium {
                    if isGeneratingSummary {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            generateSummary()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(Typography.captionLarge)
                        }
                        .accessibilityLabel(Constants.generateSummary)
                    }
                }
            }

            if isPremium {
                Text(summary)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else {
                PremiumGateView(
                    feature: .storyThreadSummary,
                    serviceLocator: serviceLocator,
                    onUnlockTapped: { isPaywallPresented = true }
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
        )
    }

    // MARK: - Articles Timeline

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Constants.articlesInThread)
                .font(Typography.titleSmall)
                .bold()
                .accessibilityAddTraits(.isHeader)

            if articles.isEmpty {
                Text(String(format: AppLocalization.localized("story_threads.article_count"), thread.articleCount))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(articles) { article in
                    timelineArticleCard(article: article)
                }
            }
        }
    }

    private func timelineArticleCard(article: Article) -> some View {
        Button {
            onArticleTapped?(article)
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Timeline indicator
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)

                    Rectangle()
                        .fill(Color.Border.adaptive(for: colorScheme))
                        .frame(width: 1)
                }
                .frame(width: 8)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(article.title)
                        .font(Typography.bodyMedium)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.xs) {
                        Text(article.source.name)
                        Text(article.formattedDate)
                    }
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Follow Button

    private var followButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            isFollowing.toggle()
            // Follow/unfollow via service would be dispatched here
        } label: {
            Label(
                isFollowing ? Constants.unfollowStory : Constants.followStory,
                systemImage: isFollowing ? "bell.fill" : "bell"
            )
            .font(Typography.labelMedium)
        }
        .accessibilityIdentifier("followThreadButton")
    }

    // MARK: - Premium

    private func generateSummary() {
        guard let service = try? serviceLocator.retrieve(StoryThreadService.self) else { return }

        isGeneratingSummary = true
        let thread = StoryThread(
            id: self.thread.id,
            title: self.thread.title,
            summary: self.thread.summary,
            articleIDs: [],
            category: self.thread.category
        )

        var cancellable: AnyCancellable?
        cancellable = service.generateThreadSummary(thread: thread)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    isGeneratingSummary = false
                    _ = cancellable // retain
                },
                receiveValue: { newSummary in
                    summary = newSummary
                }
            )
    }

    private var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else {
            return Empty().eraseToAnyPublisher()
        }
        return storeKitService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func initializeSubscriptionStatus() {
        if let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) {
            isPremium = storeKitService.isPremium
        }
    }

    private func checkPremiumStatus() {
        if let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) {
            isPremium = storeKitService.isPremium
        }
    }
}

#Preview {
    NavigationStack {
        StoryThreadDetailView(
            thread: StoryThreadItem(from: StoryThread.sampleThreads[0]),
            serviceLocator: .preview
        )
    }
    .preferredColorScheme(.dark)
}
