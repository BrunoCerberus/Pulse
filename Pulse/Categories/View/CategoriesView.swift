import SwiftUI

struct CategoriesView<R: CategoriesNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: CategoriesViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: CategoriesViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    articlesList
                        .padding(.top, Spacing.sm)
                } header: {
                    categoryChipsRow
                }
            }
        }
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .background {
            categoryBackground
                .ignoresSafeArea()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .onChange(of: viewModel.selectedArticle) { _, newValue in
            if let article = newValue {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.selectedArticle = nil
            }
        }
    }

    private var categoryBackground: some View {
        Group {
            if let category = viewModel.viewState.selectedCategory {
                LinearGradient(
                    colors: [
                        category.color.opacity(0.1),
                        Color(.systemBackground),
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            } else {
                LinearGradient.subtleBackground
            }
        }
        .animation(.easeInOut(duration: AnimationTiming.normal), value: viewModel.viewState.selectedCategory)
    }

    private var categoryChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.viewState.categories) { category in
                    Button {
                        HapticManager.shared.selectionChanged()
                        viewModel.handle(event: .onCategorySelected(category))
                    } label: {
                        GlassCategoryChip(
                            category: category,
                            style: .medium,
                            isSelected: category == viewModel.viewState.selectedCategory,
                            showIcon: true
                        )
                    }
                    .buttonStyle(.plain)
                    .pressEffect(scale: 0.95)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var articlesList: some View {
        if viewModel.viewState.selectedCategory == nil {
            selectCategoryPrompt
        } else if viewModel.viewState.isLoading {
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading articles...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical) { height, _ in
                height * 0.6
            }
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            articlesScrollView
        }
    }

    private var selectCategoryPrompt: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary)

                Text("Select a Category")
                    .font(Typography.titleMedium)

                Text("Choose a category above to see related articles.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .containerRelativeFrame(.vertical) { height, _ in
            height * 0.6
        }
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)

                Text("Error")
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
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .containerRelativeFrame(.vertical) { height, _ in
            height * 0.6
        }
    }

    private var emptyStateView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "newspaper")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)

                Text("No Articles")
                    .font(Typography.titleMedium)

                Text("No articles found in this category.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .containerRelativeFrame(.vertical) { height, _ in
            height * 0.6
        }
    }

    private var articlesScrollView: some View {
        LazyVStack(spacing: Spacing.sm) {
            if viewModel.viewState.selectedCategory != nil {
                HStack {
                    Text("\(viewModel.viewState.articles.count) articles")
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xs)
            }

            ForEach(Array(viewModel.viewState.articles.enumerated()), id: \.element.id) { index, item in
                GlassArticleCard(
                    item: item,
                    onTap: {
                        viewModel.handle(event: .onArticleTapped(item.article))
                    },
                    onBookmark: {},
                    onShare: {}
                )
                .fadeIn(delay: Double(index) * 0.03)
                .onAppear {
                    if item == viewModel.viewState.articles.last {
                        viewModel.handle(event: .onLoadMore)
                    }
                }
            }

            if viewModel.viewState.isLoadingMore {
                HStack {
                    ProgressView()
                        .tint(.secondary)
                    Text("Loading more...")
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.lg)
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

#Preview {
    NavigationStack {
        CategoriesView(
            router: CategoriesNavigationRouter(),
            viewModel: CategoriesViewModel(serviceLocator: .preview)
        )
    }
}
