import SwiftUI

struct HomeView<R: HomeNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: HomeViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: HomeViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .navigationTitle("Pulse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.route(navigationEvent: .settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                viewModel.handle(event: .onRefresh)
            }
            .sheet(item: $viewModel.shareArticle) { article in
                ShareSheet(activityItems: [URL(string: article.url) ?? article.title])
            }
            .onAppear {
                viewModel.handle(event: .onAppear)
            }
            .onChange(of: viewModel.selectedArticle) { _, newValue in
                if let article = newValue {
                    router.route(navigationEvent: .articleDetail(article))
                    viewModel.selectedArticle = nil
                }
            }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading && viewModel.viewState.headlines.isEmpty {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            articlesList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0 ..< 5, id: \.self) { _ in
                    ArticleSkeletonView()
                }
            }
            .padding()
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load News", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                viewModel.handle(event: .onRefresh)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No News Available", systemImage: "newspaper")
        } description: {
            Text("Check back later for the latest headlines.")
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !viewModel.viewState.breakingNews.isEmpty {
                    Section {
                        breakingNewsCarousel
                    } header: {
                        sectionHeader("Breaking News")
                    }
                }

                Section {
                    ForEach(viewModel.viewState.headlines) { item in
                        ArticleRowView(item: item) {
                            viewModel.handle(event: .onArticleTapped(item.article))
                        } onBookmark: {
                            viewModel.handle(event: .onBookmarkTapped(item.article))
                        } onShare: {
                            viewModel.handle(event: .onShareTapped(item.article))
                        }
                        .onAppear {
                            if item == viewModel.viewState.headlines.last {
                                viewModel.handle(event: .onLoadMore)
                            }
                        }
                    }

                    if viewModel.viewState.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                } header: {
                    sectionHeader("Top Headlines")
                }
            }
        }
    }

    private var breakingNewsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.viewState.breakingNews) { item in
                    BreakingNewsCard(item: item) {
                        viewModel.handle(event: .onArticleTapped(item.article))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        HomeView(
            router: HomeNavigationRouter(),
            viewModel: HomeViewModel(serviceLocator: .preview)
        )
    }
}
