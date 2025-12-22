import SwiftUI

struct SearchView<R: SearchNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: SearchViewModel

    /// Initial query for deeplink support
    var initialQuery: String?

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    ///   - initialQuery: Optional initial query for deeplinks
    init(router: R, viewModel: SearchViewModel, initialQuery: String? = nil) {
        self.router = router
        self.viewModel = viewModel
        self.initialQuery = initialQuery
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle("Search")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .searchable(
            text: Binding(
                get: { viewModel.viewState.query },
                set: { viewModel.handle(event: .onQueryChanged($0)) }
            ),
            prompt: "Search news..."
        )
        .onSubmit(of: .search) {
            HapticManager.shared.tap()
            viewModel.handle(event: .onSearch)
        }
        .onAppear {
            if let query = initialQuery, !query.isEmpty {
                viewModel.handle(event: .onQueryChanged(query))
                viewModel.handle(event: .onSearch)
            }
        }
        .onChange(of: viewModel.selectedArticle) { _, newValue in
            if let article = newValue {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.selectedArticle = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Searching...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if !viewModel.viewState.hasSearched {
            initialEmptyStateView
        } else if viewModel.viewState.showNoResults {
            noResultsView
        } else if viewModel.viewState.results.isEmpty {
            suggestionsView
        } else {
            resultsList
        }
    }

    private var initialEmptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Accent.primary)

                    Text("Search for News")
                        .font(Typography.titleMedium)

                    Text("Find articles from thousands of sources worldwide")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var suggestionsView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if !viewModel.viewState.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        GlassSectionHeader("Recent Searches")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(viewModel.viewState.suggestions, id: \.self) { suggestion in
                                    Button {
                                        HapticManager.shared.tap()
                                        viewModel.handle(event: .onSuggestionTapped(suggestion))
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "clock")
                                                .font(.system(size: IconSize.sm))
                                            Text(suggestion)
                                                .font(Typography.labelMedium)
                                        }
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.xs)
                                        .glassBackground(style: .thin, cornerRadius: CornerRadius.pill)
                                    }
                                    .pressEffect()
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    GlassSectionHeader("Trending Topics")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Spacing.sm) {
                        ForEach(NewsCategory.allCases) { category in
                            GlassCategoryButton(category: category, isSelected: false) {
                                viewModel.handle(event: .onQueryChanged(category.displayName))
                                viewModel.handle(event: .onSearch)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.top, Spacing.md)
        }
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.error)

                Text("Search Failed")
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onSearch)
                } label: {
                    Text("Try Again")
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                }
                .pressEffect()
            }
        }
        .padding(Spacing.lg)
    }

    private var noResultsView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)

                Text("No Results Found")
                    .font(Typography.titleMedium)

                Text("No articles found for \"\(viewModel.viewState.query)\"")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                sortPicker
                    .padding(.horizontal, Spacing.md)
                    .disabled(viewModel.viewState.isSorting)

                LazyVStack(spacing: Spacing.sm) {
                    ForEach(Array(viewModel.viewState.results.enumerated()), id: \.element.id) { index, item in
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
                            if item == viewModel.viewState.results.last {
                                viewModel.handle(event: .onLoadMore)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .opacity(viewModel.viewState.isSorting ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.viewState.isSorting)
                .overlay {
                    if viewModel.viewState.isSorting {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
                .allowsHitTesting(!viewModel.viewState.isSorting)

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
            .padding(.top, Spacing.sm)
        }
    }

    private var sortPicker: some View {
        Picker("Sort by", selection: Binding(
            get: { viewModel.viewState.sortOption },
            set: {
                HapticManager.shared.selectionChanged()
                viewModel.handle(event: .onSortChanged($0))
            }
        )) {
            ForEach(SearchSortOption.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    NavigationStack {
        SearchView(
            router: SearchNavigationRouter(),
            viewModel: SearchViewModel(serviceLocator: .preview)
        )
    }
}
