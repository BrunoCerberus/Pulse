import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var back: String {
        AppLocalization.shared.localized("common.back")
    }

    static var readFull: String {
        AppLocalization.shared.localized("article.read_full")
    }

    static var summarize: String {
        AppLocalization.shared.localized("summarization.button")
    }
}

// MARK: - ArticleDetailView

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let heroBaseHeight: CGFloat = 280
    private let serviceLocator: ServiceLocator

    @State private var isPremium = false
    @State private var isPaywallPresented = false

    init(article: Article, serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(
            article: article,
            serviceLocator: serviceLocator
        ))
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = viewModel.viewState.article.heroImageURL, let url = URL(string: imageURL) {
                        StretchyAsyncImage(
                            url: url,
                            baseHeight: heroBaseHeight,
                            accessibilityLabel: viewModel.viewState.article.title
                        )
                    }

                    contentCard
                }
            }
            .accessibilityIdentifier("articleDetailScrollView")
        }
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
                    .accessibilityHint(isPremium ? AppLocalization.shared.localized("article_detail.summarize_hint") : AppLocalization.shared.localized("article_detail.premium_hint"))

                    Button("", systemImage: viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.handle(event: .onBookmarkTapped)
                    }
                    .accessibilityIdentifier(viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(
                        viewModel.viewState.isBookmarked
                            ? AppLocalization.shared.localized("article_detail.remove_bookmark")
                            : AppLocalization.shared.localized("article_detail.add_bookmark")
                    )
                    .accessibilityHint(AppLocalization.shared.localized("article_detail.save_hint"))

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.handle(event: .onShareTapped)
                    }
                    .accessibilityIdentifier("square.and.arrow.up")
                    .accessibilityLabel(AppLocalization.shared.localized("article_detail.share_label"))
                    .accessibilityHint(AppLocalization.shared.localized("article_detail.share_hint"))
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showShareSheet },
            set: { if !$0 { viewModel.handle(event: .onShareSheetDismissed) } }
        )) {
            if let url = URL(string: viewModel.viewState.article.url) {
                ShareSheet(activityItems: [url])
            }
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
        .onChange(of: viewModel.viewState.isBookmarked) { _, isBookmarked in
            let announcement = isBookmarked
                ? AppLocalization.shared.localized("accessibility.bookmark_added")
                : AppLocalization.shared.localized("accessibility.bookmark_removed")
            AccessibilityNotification.Announcement(announcement).post()
        }
        .enableSwipeBack()
    }

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
        }
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
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            Logger.shared.warning("Failed to retrieve StoreKitService: \(error)", category: "ArticleDetail")
            isPremium = false
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let category = viewModel.viewState.article.category {
                GlassCategoryChip(category: category, style: .medium, showIcon: true)
                    .glowEffect(color: category.color, radius: 6)
            }

            Text(viewModel.viewState.article.title)
                .font(Typography.titleLarge)
                .fontWeight(.bold)
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

            readFullArticleButton
        }
        .padding(Spacing.lg)
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
                    Text(String(format: AppLocalization.shared.localized("article.by_author"), author))
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
                    Text(String(format: AppLocalization.shared.localized("article.by_author"), author))
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
        .accessibilityHint(AppLocalization.shared.localized("accessibility.opens_in_safari"))
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
