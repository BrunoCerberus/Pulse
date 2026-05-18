// swiftlint:disable file_length
import Combine
import EntropyCore
import SwiftUI

// MARK: - ArticleDetailView

// swiftlint:disable:next type_body_length
struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let heroBaseHeight: CGFloat = 280
    private let readingMaxWidth: CGFloat = 720
    private let serviceLocator: ServiceLocator
    private let onRelatedArticleTapped: ((Article) -> Void)?

    @ScaledMetric(relativeTo: .body) private var relatedArticleCardHeight: CGFloat = 96

    @State private var isPremium = false
    @State private var isPaywallPresented = false

    init(
        article: Article,
        serviceLocator: ServiceLocator,
        onRelatedArticleTapped: ((Article) -> Void)? = nil
    ) {
        self.serviceLocator = serviceLocator
        self.onRelatedArticleTapped = onRelatedArticleTapped
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(
            article: article,
            serviceLocator: serviceLocator
        ))
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    LinearGradient.subtleBackground
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if let imageURL = viewModel.viewState.article.heroImageURL,
                               let url = URL(string: imageURL)
                            {
                                StretchyAsyncImage(
                                    url: url,
                                    baseHeight: heroBaseHeight,
                                    accessibilityLabel: viewModel.viewState.article.title
                                )
                            }

                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                contentCard(minHeight: contentCardMinHeight(in: proxy))
                                    .frame(maxWidth: horizontalSizeClass == .regular ? readingMaxWidth : .infinity)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .accessibilityIdentifier("articleDetailScrollView")
                }
            }

            if viewModel.viewState.isTTSPlayerVisible {
                SpeechPlayerBarView(
                    title: viewModel.viewState.article.title,
                    playbackState: viewModel.viewState.ttsPlaybackState,
                    progress: viewModel.viewState.ttsProgress,
                    speedPreset: viewModel.viewState.ttsSpeedPreset,
                    onPlayPause: { viewModel.handle(event: .onTTSPlayPauseTapped) },
                    onStop: { viewModel.handle(event: .onTTSStopTapped) },
                    onSpeedTap: { viewModel.handle(event: .onTTSSpeedTapped) }
                )
                .frame(maxWidth: horizontalSizeClass == .regular ? readingMaxWidth : .infinity)
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityIdentifier("speechPlayerBar")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.viewState.isTTSPlayerVisible)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(Constants.back, systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("backButton")
                .accessibilityLabel(Constants.back)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button("", systemImage: "speaker.wave.2") {
                        viewModel.handle(event: .onListenTapped)
                    }
                    .accessibilityIdentifier("listenButton")
                    .accessibilityLabel(Constants.listen)
                    .accessibilityHint(Constants.listenHint)

                    Button("", systemImage: "sparkles") {
                        if isPremium {
                            viewModel.handle(event: .onSummarizeTapped)
                        } else {
                            HapticManager.shared.notification(.warning)
                            isPaywallPresented = true
                        }
                    }
                    .accessibilityIdentifier("summarizeButton")
                    .accessibilityLabel(Constants.summarize)
                    .accessibilityHint(
                        isPremium
                            ? Constants.summarizeHint
                            : Constants.premiumHint
                    )

                    Button("", systemImage: viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.handle(event: .onBookmarkTapped)
                    }
                    .accessibilityIdentifier(viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(
                        viewModel.viewState.isBookmarked
                            ? Constants.removeBookmark
                            : Constants.addBookmark
                    )
                    .accessibilityHint(Constants.saveHint)

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.handle(event: .onShareTapped)
                    }
                    .accessibilityIdentifier("square.and.arrow.up")
                    .accessibilityLabel(Constants.shareLabel)
                    .accessibilityHint(Constants.shareHint)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showShareSheet },
            set: { if !$0 { viewModel.handle(event: .onShareSheetDismissed) } }
        )) {
            ShareSheet(activityItems: ShareItemsBuilder.activityItems(for: viewModel.viewState.article))
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showSummarizationSheet },
            set: { if !$0 { viewModel.handle(event: .onSummarizationSheetDismissed) } }
        )) {
            SummarizationSheet(
                viewModel: SummarizationViewModel(
                    article: viewModel.viewState.article,
                    serviceLocator: serviceLocator
                )
            )
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
            seedPremiumFromCache()
        }
        .task {
            await refreshPremiumStatus()
        }
        .onDisappear {
            viewModel.handle(event: .onDisappear)
        }
        .onReceive(subscriptionStatusPublisher) { newStatus in
            isPremium = newStatus
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: {
                Task { await refreshPremiumStatus() }
            },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
        .onChange(of: viewModel.viewState.isBookmarked) { _, isBookmarked in
            let announcement = isBookmarked
                ? Constants.bookmarkAdded
                : Constants.bookmarkRemoved
            AccessibilityNotification.Announcement(announcement).post()
        }
        .onChange(of: viewModel.viewState.ttsPlaybackState) { _, newState in
            let announcement: String? = switch newState {
            case .playing:
                Constants.ttsStarted
            case .paused:
                Constants.ttsPaused
            case .idle:
                nil
            }
            if let announcement {
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
        .enableSwipeBack()
    }

    /// Seeds `isPremium` from the cached StoreKit value for an instant first
    /// render, before `.task` re-verifies against StoreKit 2.
    private func seedPremiumFromCache() {
        if let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) {
            isPremium = storeKitService.isPremium
        }
    }

    /// Forces a re-read of StoreKit 2 entitlements instead of trusting the
    /// in-memory cached `isPremium`. See `StoreKitService.refreshSubscriptionStatus`
    /// for why premium gates can't rely on the cached value alone.
    @MainActor
    private func refreshPremiumStatus() async {
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else {
            isPremium = false
            return
        }
        let boxed = UncheckedSendableBox(value: storeKitService)
        isPremium = await boxed.value.refreshSubscriptionStatus()
    }

    private var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else {
            return Empty().eraseToAnyPublisher()
        }
        return storeKitService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Sizes the card to fill below the hero so `.regularMaterial` doesn't expose the gradient at the bottom.
    private func contentCardMinHeight(in proxy: GeometryProxy) -> CGFloat {
        max(proxy.size.height - heroBaseHeight + Spacing.lg, 0)
    }

    private func contentCard(minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let category = viewModel.viewState.article.category {
                GlassCategoryChip(category: category, style: .medium, showIcon: true)
                    .glowEffect(color: category.color, radius: 6)
            }

            Text(viewModel.viewState.article.title)
                .font(Typography.titleLarge)
                .bold()
                .accessibilityAddTraits(.isHeader)

            metadataRow

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            if let description = viewModel.viewState.processedDescription {
                Text(description)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineSpacing(8)
                    .padding(.leading, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.Accent.gradient)
                            .frame(width: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    }
            }

            if let content = viewModel.viewState.processedContent {
                Text(content)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(6)
            }

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            contentAttribution

            readFullArticleButton

            if !viewModel.viewState.relatedArticles.isEmpty {
                relatedArticlesSection
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
        .background(.regularMaterial)
        .clipShape(
            .rect(
                topLeadingRadius: CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.xl
            )
        )
        .offset(y: -Spacing.lg)
    }

    @ViewBuilder
    private var metadataRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let author = viewModel.viewState.article.author {
                    Text(String(format: Constants.byAuthor, author))
                        .fontWeight(.medium)
                }

                Text(viewModel.viewState.article.source.name)

                Text(viewModel.viewState.article.formattedDate)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        } else {
            HStack(spacing: Spacing.xs) {
                if let author = viewModel.viewState.article.author {
                    Text(String(format: Constants.byAuthor, author))
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(-1)

                    Circle()
                        .fill(.secondary)
                        .frame(width: 3, height: 3)
                        .accessibilityHidden(true)
                }

                Text(viewModel.viewState.article.source.name)
                    .lineLimit(1)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)

                Text(viewModel.viewState.article.formattedDate)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        }
    }

    private var relatedArticlesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            Text(Constants.relatedArticles)
                .font(Typography.titleMedium)
                .bold()
                .accessibilityAddTraits(.isHeader)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: Spacing.md) {
                    ForEach(viewModel.viewState.relatedArticles) { item in
                        relatedArticleCard(for: item)
                    }
                }
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: Spacing.sm) {
                        ForEach(viewModel.viewState.relatedArticles) { item in
                            relatedArticleCard(for: item)
                                .frame(width: 260, height: relatedArticleCardHeight)
                        }
                    }
                }
                .frame(height: relatedArticleCardHeight)
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func relatedArticleCard(for item: ArticleViewItem) -> some View {
        GlassArticleCardCompact(
            title: item.title,
            sourceName: item.sourceName,
            imageURL: item.imageURL,
            onTap: {
                if let article = viewModel.viewState.relatedArticleModels
                    .first(where: { $0.id == item.id })
                {
                    onRelatedArticleTapped?(article)
                }
            }
        )
    }

    private var contentAttribution: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "link")
                .font(.system(size: IconSize.xs))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(String(
                format: Constants.contentAttributionFormat,
                viewModel.viewState.article.source.name
            ))
            .font(Typography.captionSmall)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var readFullArticleButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            viewModel.handle(event: .onReadFullTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "safari.fill")
                Text(Constants.readFull)
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.Accent.gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
        .pressEffect()
        .accessibilityHint(Constants.opensInSafari)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article.mockArticles[0],
            serviceLocator: .preview
        )
    }
    .preferredColorScheme(.dark)
}
