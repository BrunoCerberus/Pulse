import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showArticleDetail = false
    @State private var showSettings = false

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: HomeViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pulse")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .navigationDestination(isPresented: $showArticleDetail) {
                    if let article = viewModel.selectedArticle {
                        ArticleDetailView(article: article, serviceLocator: serviceLocator)
                    }
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView(serviceLocator: serviceLocator)
                }
                .refreshable {
                    viewModel.handle(event: .onRefresh)
                }
                .sheet(item: $viewModel.shareArticle) { article in
                    ShareSheet(activityItems: [URL(string: article.url) ?? article.title])
                }
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.selectedArticle) { _, newValue in
            showArticleDetail = newValue != nil
        }
    }

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
