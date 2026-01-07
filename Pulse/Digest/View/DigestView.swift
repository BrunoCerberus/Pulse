import SwiftUI

// MARK: - DigestView

struct DigestView<R: DigestNavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: DigestViewModel

    init(router: R, viewModel: DigestViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(DigestConstants.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onDisappear {
            viewModel.handle(event: .onDisappear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.showOnboarding {
            onboardingView
        } else if viewModel.viewState.isGenerating {
            DigestGeneratingView(
                generationProgress: viewModel.viewState.generationProgress,
                onCancel: { viewModel.handle(event: .onCancelTapped) }
            )
        } else if let digest = viewModel.viewState.digest {
            DigestResultView(
                digest: digest,
                onClear: { viewModel.handle(event: .onClearTapped) }
            )
        } else {
            sourceSelectionView
        }
    }

    // MARK: - Onboarding View

    private var onboardingView: some View {
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

                        Text(DigestConstants.title)
                            .font(Typography.displaySmall)

                        Text(DigestConstants.subtitle)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                // Source selection
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(DigestConstants.selectSource)
                        .font(Typography.titleSmall)
                        .padding(.horizontal, Spacing.lg)

                    ForEach(viewModel.viewState.sources) { source in
                        DigestSourceCard(
                            source: source,
                            isSelected: source == viewModel.viewState.selectedSource,
                            onTap: {
                                HapticManager.shared.selectionChanged()
                                viewModel.handle(event: .onSourceSelected(source))
                            }
                        )
                    }
                }

                DigestModelStatusIndicator(modelStatus: viewModel.viewState.modelStatus)
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Source Selection with Articles

    private var sourceSelectionView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                sourceChipsRow

                if case let .loading(progress) = viewModel.viewState.modelStatus {
                    DigestModelLoadingBar(progress: progress)
                }

                if let error = viewModel.viewState.errorMessage {
                    DigestErrorView(
                        message: error,
                        onRetry: { viewModel.handle(event: .onRetryTapped) }
                    )
                } else if viewModel.viewState.showNoTopicsError {
                    DigestNoTopicsView(
                        onConfigureTopics: { router.route(navigationEvent: .settings) }
                    )
                } else if viewModel.viewState.showEmptyState {
                    DigestEmptyStateView()
                } else if viewModel.viewState.isLoadingArticles {
                    DigestLoadingView()
                } else {
                    articlesPreview
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    private var sourceChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.viewState.sources) { source in
                    DigestSourceChip(
                        source: source,
                        isSelected: source == viewModel.viewState.selectedSource,
                        onTap: {
                            HapticManager.shared.selectionChanged()
                            viewModel.handle(event: .onSourceSelected(source))
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .accessibilityIdentifier("digestSourceChipsScrollView")
    }

    private var articlesPreview: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("\(viewModel.viewState.articleCount) \(DigestConstants.articlesAvailable)")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)

            ForEach(viewModel.viewState.articlePreviews.prefix(3)) { article in
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

            if viewModel.viewState.articleCount > 3 {
                Text("+ \(viewModel.viewState.articleCount - 3) \(DigestConstants.moreArticles)")
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }

            DigestGenerateButton(
                canGenerate: viewModel.viewState.canGenerate,
                onTap: { viewModel.handle(event: .onGenerateTapped) }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
        }
    }
}

#Preview {
    NavigationStack {
        DigestView(
            router: DigestNavigationRouter(),
            viewModel: DigestViewModel(serviceLocator: .preview)
        )
    }
}
