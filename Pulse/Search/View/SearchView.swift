import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "search.title")
    static let searching = String(localized: "search.searching")
    static let placeholderTitle = String(localized: "search.placeholder.title")
    static let placeholderMessage = String(localized: "search.placeholder.message")
    static let errorTitle = String(localized: "search.error.title")
    static let emptyTitle = String(localized: "search.empty.title")
    static let tryAgain = String(localized: "common.try_again")
    static let loadingMore = String(localized: "common.loading_more")
}

// MARK: - SearchView

struct SearchView<R: SearchNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: SearchViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: SearchViewModel) {
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
        .searchable(
            text: Binding(
                get: { viewModel.viewState.query },
                set: { viewModel.handle(event: .onQueryChanged($0)) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "search.prompt")
        )
        .onSubmit(of: .search) {
            HapticManager.shared.tap()
            viewModel.handle(event: .onSearch)
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
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(Constants.searching)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.viewState.results.isEmpty {
            // Show existing results even if a re-search failed (e.g., offline with prior results)
            resultsList
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
                        .font(.largeTitle)
                        .foregroundStyle(Color.Accent.primary)
                        .accessibilityHidden(true)

                    Text(Constants.placeholderTitle)
                        .font(Typography.titleMedium)

                    Text(Constants.placeholderMessage)
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
                        GlassSectionHeader(String(localized: "search.recent_searches"))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(viewModel.viewState.suggestions, id: \.self) { suggestion in
                                    Button {
                                        HapticManager.shared.tap()
                                        viewModel.handle(event: .onSuggestionTapped(suggestion))
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "clock")
                                                .font(.body)
                                            Text(suggestion)
                                                .font(Typography.labelMedium)
                                        }
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.xs)
                                        .glassBackground(style: .thin, cornerRadius: CornerRadius.pill)
                                    }
                                    .pressEffect()
                                    .accessibilityLabel("Recent search: \(suggestion)")
                                    .accessibilityHint("Double tap to search")
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    GlassSectionHeader(String(localized: "search.trending_topics"))

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
                if viewModel.viewState.isOfflineError {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)

                    Text(String(localized: "search.offline.title"))
                        .font(Typography.titleMedium)

                    Text(String(localized: "search.offline.message"))
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.Semantic.error)
                        .accessibilityHidden(true)

                    Text(Constants.errorTitle)
                        .font(Typography.titleMedium)

                    Text(message)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onSearch)
                    } label: {
                        Text(Constants.tryAgain)
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
        }
        .padding(Spacing.lg)
    }

    private var noResultsView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(Constants.emptyTitle)
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
        let results = viewModel.viewState.results
        let lastItemId = results.last?.id

        return ScrollView {
            LazyVStack(spacing: Spacing.md) {
                sortPicker
                    .padding(.horizontal, Spacing.md)
                    .disabled(viewModel.viewState.isSorting)

                LazyVStack(spacing: Spacing.sm) {
                    ForEach(results) { item in
                        GlassArticleCard(
                            item: item,
                            onTap: {
                                viewModel.handle(event: .onArticleTapped(articleId: item.id))
                            },
                            onBookmark: {},
                            onShare: {}
                        )
                        .fadeIn(delay: Double(item.animationIndex) * 0.03)
                        .onAppear {
                            // Pre-computed lastItemId avoids recalculating .last on every appear
                            if item.id == lastItemId {
                                viewModel.handle(event: .onLoadMore)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .allowsHitTesting(!viewModel.viewState.isSorting)
                .overlay {
                    if viewModel.viewState.isSorting {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .background(.ultraThinMaterial.opacity(0.5))
                    }
                }

                if viewModel.viewState.isLoadingMore {
                    HStack {
                        ProgressView()
                            .tint(.secondary)
                        Text(Constants.loadingMore)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.lg)
                }
            }
            .padding(.top, Spacing.sm)
        }
    }
}

// MARK: - Sort Picker

private extension SearchView {
    var sortPicker: some View {
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
    .preferredColorScheme(.dark)
}
