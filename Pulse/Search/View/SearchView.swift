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
        content
            .navigationTitle("Search")
            .searchable(
                text: Binding(
                    get: { viewModel.viewState.query },
                    set: { viewModel.handle(event: .onQueryChanged($0)) }
                ),
                prompt: "Search news..."
            )
            .onSubmit(of: .search) {
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
            ProgressView("Searching...")
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
        ContentUnavailableView {
            Label("Search for News", systemImage: "magnifyingglass")
        } description: {
            Text("Find articles from thousands of sources worldwide")
        }
    }

    private var suggestionsView: some View {
        List {
            if !viewModel.viewState.suggestions.isEmpty {
                Section("Recent Searches") {
                    ForEach(viewModel.viewState.suggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.handle(event: .onSuggestionTapped(suggestion))
                        } label: {
                            Label(suggestion, systemImage: "clock")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            Section("Trending Topics") {
                ForEach(NewsCategory.allCases) { category in
                    Button {
                        viewModel.handle(event: .onQueryChanged(category.displayName))
                        viewModel.handle(event: .onSearch)
                    } label: {
                        Label(category.displayName, systemImage: category.icon)
                            .foregroundStyle(category.color)
                    }
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Search Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                viewModel.handle(event: .onSearch)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results Found", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("No articles found for \"\(viewModel.viewState.query)\"")
        }
    }

    private var resultsList: some View {
        List {
            Section {
                sortPicker
            }

            Section {
                ForEach(viewModel.viewState.results) { item in
                    ArticleRowView(item: item) {
                        viewModel.handle(event: .onArticleTapped(item.article))
                    } onBookmark: {} onShare: {}
                        .listRowInsets(EdgeInsets())
                        .onAppear {
                            if item == viewModel.viewState.results.last {
                                viewModel.handle(event: .onLoadMore)
                            }
                        }
                }

                if viewModel.viewState.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var sortPicker: some View {
        Picker("Sort by", selection: Binding(
            get: { viewModel.viewState.sortOption },
            set: { viewModel.handle(event: .onSortChanged($0)) }
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
