import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("reading_history.title")
    }

    static var emptyTitle: String {
        AppLocalization.localized("reading_history.empty.title")
    }

    static var emptyMessage: String {
        AppLocalization.localized("reading_history.empty.message")
    }

    static var clearHistory: String {
        AppLocalization.localized("reading_history.clear")
    }

    static var clearConfirm: String {
        AppLocalization.localized("reading_history.clear.confirm")
    }

    static var errorTitle: String {
        AppLocalization.localized("bookmarks.error.title")
    }

    static var tryAgain: String {
        AppLocalization.localized("common.try_again")
    }
}

// MARK: - ReadingHistoryView

struct ReadingHistoryView<R: ReadingHistoryNavigationRouter>: View {
    private var router: R

    @ObservedObject var viewModel: ReadingHistoryViewModel
    @State private var showClearConfirmation = false

    init(router: R, viewModel: ReadingHistoryViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if !viewModel.viewState.articles.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(Typography.bodyMedium)
                    }
                }
            }
        }
        .alert(Constants.clearHistory, isPresented: $showClearConfirmation) {
            Button(AppLocalization.localized("common.cancel"), role: .cancel) {}
            Button(Constants.clearHistory, role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onClearHistoryTapped)
            }
        } message: {
            Text(Constants.clearConfirm)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .sheet(item: Binding(
            get: { viewModel.viewState.articleToShare },
            set: { _ in viewModel.handle(event: .onShareDismissed) }
        )) { article in
            ShareSheet(activityItems: [URL(string: article.url) ?? article.title])
        }
        .onChange(of: viewModel.viewState.selectedArticle) { _, newValue in
            if let article = newValue {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.handle(event: .onArticleNavigated)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            historyList
        }
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.Semantic.warning)
                    .accessibilityHidden(true)

                Text(Constants.errorTitle)
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onAppear)
                } label: {
                    Text(Constants.tryAgain)
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
        .padding(Spacing.lg)
    }

    private var emptyStateView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(Color.Accent.primary)
                    .accessibilityHidden(true)

                Text(Constants.emptyTitle)
                    .font(Typography.titleMedium)

                Text(Constants.emptyMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.viewState.articles) { item in
                    GlassArticleCard(
                        item: item,
                        onTap: {
                            viewModel.handle(event: .onArticleTapped(articleId: item.id))
                        },
                        onBookmark: {
                            HapticManager.shared.notification(.success)
                            viewModel.handle(event: .onBookmarkTapped(articleId: item.id))
                        },
                        onShare: {
                            viewModel.handle(event: .onShareTapped(articleId: item.id))
                        }
                    )
                    .fadeIn(delay: Double(item.animationIndex) * 0.03)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }
}
