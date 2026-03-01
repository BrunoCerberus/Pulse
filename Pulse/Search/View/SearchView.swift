import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("search.title")
    }

    static var searching: String {
        AppLocalization.localized("search.searching")
    }

    static var placeholderTitle: String {
        AppLocalization.localized("search.placeholder.title")
    }

    static var placeholderMessage: String {
        AppLocalization.localized("search.placeholder.message")
    }

    static var errorTitle: String {
        AppLocalization.localized("search.error.title")
    }

    static var emptyTitle: String {
        AppLocalization.localized("search.empty.title")
    }

    static var tryAgain: String {
        AppLocalization.localized("common.try_again")
    }

    static var loadingMore: String {
        AppLocalization.localized("common.loading_more")
    }

    static var prompt: String {
        AppLocalization.localized("search.prompt")
    }

    static var searchResultsCount: String {
        AppLocalization.localized("accessibility.search_results_count")
    }

    static var searchNoResults: String {
        AppLocalization.localized("accessibility.search_no_results")
    }

    static var recentSearches: String {
        AppLocalization.localized("search.recent_searches")
    }

    static var trendingTopics: String {
        AppLocalization.localized("search.trending_topics")
    }

    static var recentLabel: String {
        AppLocalization.localized("search.recent_label")
    }

    static var searchHint: String {
        AppLocalization.localized("search.search_hint")
    }

    static var offlineTitle: String {
        AppLocalization.localized("search.offline.title")
    }

    static var offlineMessage: String {
        AppLocalization.localized("search.offline.message")
    }

    static var noResults: String {
        AppLocalization.localized("search.no_results")
    }

    static var sortBy: String {
        AppLocalization.localized("search.sort_by")
    }
}

// MARK: - SearchView

struct SearchView<R: SearchNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: SearchViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AccessibilityFocusState private var isFirstResultFocused: Bool

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
            prompt: Constants.prompt
        )
        .onSubmit(of: .search) {
            HapticManager.shared.tap()
            viewModel.handle(event: .onSearch)
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
        .onChange(of: viewModel.viewState.results) { _, newResults in
            if !newResults.isEmpty {
                isFirstResultFocused = true
                let announcement = String(format: Constants.searchResultsCount, newResults.count)
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
        .onChange(of: viewModel.viewState.showNoResults) { _, showNoResults in
            if showNoResults {
                AccessibilityNotification.Announcement(Constants.searchNoResults).post()
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
                        GlassSectionHeader(Constants.recentSearches)

                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                ForEach(viewModel.viewState.suggestions, id: \.self) { suggestion in
                                    suggestionChip(suggestion)
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(viewModel.viewState.suggestions, id: \.self) { suggestion in
                                        suggestionChip(suggestion)
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    GlassSectionHeader(Constants.trendingTopics)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 150 : 100))], spacing: Spacing.sm) {
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

    private func suggestionChip(_ suggestion: String) -> some View {
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
        .accessibilityLabel(String(format: Constants.recentLabel, suggestion))
        .accessibilityHint(Constants.searchHint)
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                if viewModel.viewState.isOfflineError {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)

                    Text(Constants.offlineTitle)
                        .font(Typography.titleMedium)

                    Text(Constants.offlineMessage)
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

                Text(String(format: Constants.noResults, viewModel.viewState.query))
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
                            onBookmark: {
                                HapticManager.shared.notification(.success)
                                viewModel.handle(event: .onBookmarkTapped(articleId: item.id))
                            },
                            onShare: {
                                viewModel.handle(event: .onShareTapped(articleId: item.id))
                            }
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
                .accessibilityFocused($isFirstResultFocused)
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
        Picker(Constants.sortBy, selection: Binding(
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
