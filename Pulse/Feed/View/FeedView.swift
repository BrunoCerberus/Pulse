import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = "Daily Digest"
    static let headerTitle = "Your Daily Digest"
    static let emptyTitle = "No Recent Reading"
    static let emptyMessage = "Read some articles to get your personalized daily digest."
    static let generatingMessage = "Creating your digest..."
    static let loadingModelMessage = "Loading AI model..."
    static let errorTitle = "Something went wrong"
    static let tryAgain = "Try Again"
    static let cancel = "Cancel"
    static let startReading = "Start Reading"
}

// MARK: - FeedView

struct FeedView<R: FeedNavigationRouter>: View {
    private var router: R

    @ObservedObject var viewModel: FeedViewModel

    init(router: R, viewModel: FeedViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                refreshButton
            }
        }
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selectedArticle) { _, article in
            if let article {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.handle(event: .onArticleNavigated)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient.subtleBackground
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState.displayState {
        case .idle:
            idleContent
        case .loading:
            loadingView
        case let .loadingModel(progress):
            loadingModelView(progress: progress)
        case .generating:
            generatingView
        case .completed:
            digestContent
        case .empty:
            emptyStateView
        case .error:
            errorView
        }
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button {
            HapticManager.shared.tap()
            viewModel.handle(event: .onRefresh)
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: IconSize.md))
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("Refresh Digest")
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        VStack(spacing: Spacing.lg) {
            dateHeader

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Accent.gradient)

                    Text("Generate Your Digest")
                        .font(Typography.titleMedium)

                    Text("Tap the button below to create a summary of your recent reading.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticManager.shared.buttonPress()
                        viewModel.handle(event: .onGenerateDigestTapped)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                            Text("Generate Digest")
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.Accent.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                    .pressEffect()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                dateHeader

                DigestCardSkeleton()
                    .padding(.horizontal, Spacing.md)

                SourceArticlesSkeleton()
                    .padding(.horizontal, Spacing.md)
            }
        }
    }

    // MARK: - Loading Model View

    private func loadingModelView(progress: Double) -> some View {
        VStack(spacing: Spacing.lg) {
            dateHeader

            GlassCard(style: .regular, shadowStyle: .medium, padding: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    ZStack {
                        // Background track
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        // Progress fill with gradient
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.Accent.gradient)
                                .frame(width: geometry.size.width * progress)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)

                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color.Accent.primary)

                        Text(Constants.loadingModelMessage)
                            .font(Typography.bodySmall)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(Int((progress * 100).rounded()))%")
                        .font(Typography.headlineSmall)
                        .foregroundStyle(Color.Accent.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: progress)
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                dateHeader

                GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.lg) {
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            TypingIndicator()

                            Text(Constants.generatingMessage)
                                .font(Typography.bodyMedium)
                                .foregroundStyle(.secondary)
                        }

                        if !viewModel.viewState.streamingText.isEmpty {
                            StreamingTextView(text: viewModel.viewState.streamingText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            HapticManager.shared.tap()
                            viewModel.handle(event: .onCancelGenerationTapped)
                        } label: {
                            Text(Constants.cancel)
                                .font(Typography.labelMedium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .pressEffect()
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    // MARK: - Digest Content

    private var digestContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                dateHeader

                if let digest = viewModel.viewState.digest {
                    DigestCard(digest: digest)
                        .padding(.horizontal, Spacing.md)
                }

                if !viewModel.viewState.sourceArticles.isEmpty {
                    SourceArticlesSection(
                        articles: viewModel.viewState.sourceArticles,
                        onArticleTapped: { article in
                            viewModel.handle(event: .onArticleTapped(article.article))
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            FeedEmptyStateView()
                .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            dateHeader

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text(Constants.errorTitle)
                        .font(Typography.titleMedium)

                    if let error = viewModel.viewState.errorMessage {
                        Text(error)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onRetryTapped)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text(Constants.tryAgain)
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .pressEffect()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Constants.headerTitle)
                    .font(Typography.titleLarge)
                Text(viewModel.viewState.headerDate)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var animatingDot = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Color.Accent.primary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animatingDot == index ? 1.3 : 0.8)
                    .opacity(animatingDot == index ? 1 : 0.5)
            }
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    withAnimation(.easeInOut(duration: 0.2)) {
                        animatingDot = (animatingDot + 1) % 3
                    }
                } catch {
                    break
                }
            }
        }
    }
}

// MARK: - Skeleton Views

private struct DigestCardSkeleton: View {
    var body: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(width: 100, height: 16)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(width: 200, height: 14)
                }
            }
        }
        .shimmer()
    }
}

private struct SourceArticlesSkeleton: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0 ..< 3, id: \.self) { _ in
                GlassCard(style: .ultraThin, shadowStyle: .subtle, padding: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.Semantic.skeleton)
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(Color.Semantic.skeleton)
                                .frame(height: 14)

                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(Color.Semantic.skeleton)
                                .frame(width: 100, height: 12)
                        }

                        Spacer()
                    }
                }
            }
        }
        .shimmer()
    }
}

#Preview {
    NavigationStack {
        FeedView(
            router: FeedNavigationRouter(),
            viewModel: FeedViewModel(serviceLocator: .preview)
        )
    }
}
