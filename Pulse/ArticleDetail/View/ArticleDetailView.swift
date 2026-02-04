import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let back = String(localized: "common.back")
    static let readFull = String(localized: "article.read_full")
    static let summarize = String(localized: "summarization.button")
}

// MARK: - ArticleDetailView

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private let heroBaseHeight: CGFloat = 280
    private let serviceLocator: ServiceLocator

    @State private var isPremium = false
    @State private var isPaywallPresented = false
    @State private var subscriptionCancellable: AnyCancellable?

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
                    .accessibilityHint(isPremium ? "Generate AI summary" : "Premium feature")

                    Button("", systemImage: viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.handle(event: .onBookmarkTapped)
                    }
                    .accessibilityIdentifier(viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(viewModel.viewState.isBookmarked ? "Remove bookmark" : "Add bookmark")
                    .accessibilityHint("Save article for offline reading")

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.handle(event: .onShareTapped)
                    }
                    .accessibilityIdentifier("square.and.arrow.up")
                    .accessibilityLabel("Share article")
                    .accessibilityHint("Share this article with others")
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
            observeSubscriptionStatus()
        }
        .onDisappear {
            subscriptionCancellable?.cancel()
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
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

    private func observeSubscriptionStatus() {
        subscriptionCancellable?.cancel()
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            // Set initial status immediately to avoid UI flicker
            isPremium = storeKitService.isPremium
            // Then observe for changes
            subscriptionCancellable = storeKitService.subscriptionStatusPublisher
                .receive(on: DispatchQueue.main)
                .sink { newStatus in
                    self.isPremium = newStatus
                }
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

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            if let author = viewModel.viewState.article.author {
                Text("By \(author)")
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
            }

            Text(viewModel.viewState.article.source.name)
                .lineLimit(1)

            Circle()
                .fill(.secondary)
                .frame(width: 3, height: 3)

            Text(viewModel.viewState.article.formattedDate)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .font(Typography.captionLarge)
        .foregroundStyle(.secondary)
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
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article.mockArticles[0],
            serviceLocator: .preview
        )
    }
}
