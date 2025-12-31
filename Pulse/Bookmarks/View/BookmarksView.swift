import SwiftUI

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
        .navigationTitle("Bookmarks")
        .toolbarBackground(.hidden, for: .navigationBar)
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
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
                Text("Loading bookmarks...")
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
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)

                Text("Unable to Load Bookmarks")
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onRefresh)
                } label: {
                    Text("Try Again")
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
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary)

                Text("No Bookmarks")
                    .font(Typography.titleMedium)

                Text("Articles you bookmark will appear here for offline reading.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
    }

    private var bookmarksList: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                bookmarkCountHeader

                ForEach(Array(viewModel.viewState.bookmarks.enumerated()), id: \.element.id) { index, item in
                    GlassArticleCard(
                        item: item,
                        isBookmarked: true,
                        onTap: {
                            viewModel.handle(event: .onArticleTapped(item.article))
                        },
                        onBookmark: {
                            HapticManager.shared.notification(.warning)
                            viewModel.handle(event: .onRemoveBookmark(item.article))
                        },
                        onShare: {}
                    )
                    .fadeIn(delay: Double(index) * 0.03)
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
            Text("\(viewModel.viewState.bookmarks.count) saved articles")
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.bottom, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        BookmarksView(
            router: BookmarksNavigationRouter(),
            viewModel: BookmarksViewModel(serviceLocator: .preview)
        )
    }
}
