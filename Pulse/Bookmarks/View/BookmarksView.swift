import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("bookmarks.title")
    }

    static var loading: String {
        AppLocalization.localized("bookmarks.loading")
    }

    static var errorTitle: String {
        AppLocalization.localized("bookmarks.error.title")
    }

    static var emptyTitle: String {
        AppLocalization.localized("bookmarks.empty.title")
    }

    static var emptyMessage: String {
        AppLocalization.localized("bookmarks.empty.message")
    }

    static var tryAgain: String {
        AppLocalization.localized("common.try_again")
    }

    static var savedCount: String {
        AppLocalization.localized("bookmarks.saved_count")
    }
}

// MARK: - BookmarksView

struct BookmarksView<R: BookmarksNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: BookmarksViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: BookmarksViewModel) {
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
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
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
        if viewModel.viewState.isRefreshing || viewModel.viewState.isLoading {
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(Constants.loading)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            bookmarksList
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
                    viewModel.handle(event: .onRefresh)
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
                Image(systemName: "bookmark")
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

    private var bookmarksList: some View {
        let bookmarks = viewModel.viewState.bookmarks

        return ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                bookmarkCountHeader

                ForEach(bookmarks) { item in
                    GlassArticleCard(
                        item: item,
                        isBookmarked: true,
                        onTap: {
                            viewModel.handle(event: .onArticleTapped(articleId: item.id))
                        },
                        onBookmark: {
                            HapticManager.shared.notification(.warning)
                            viewModel.handle(event: .onRemoveBookmark(articleId: item.id))
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

    private var bookmarkCountHeader: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Color.Accent.primary)
            Text(String(format: Constants.savedCount, viewModel.viewState.bookmarks.count))
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack {
        BookmarksView(
            router: BookmarksNavigationRouter(),
            viewModel: BookmarksViewModel(serviceLocator: .preview)
        )
    }
    .preferredColorScheme(.dark)
}
