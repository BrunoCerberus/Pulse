import SwiftUI

struct ForYouView: View {
    @StateObject private var viewModel: ForYouViewModel
    @State private var showArticleDetail = false

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: ForYouViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("For You")
                .navigationDestination(isPresented: $showArticleDetail) {
                    if let article = viewModel.selectedArticle {
                        ArticleDetailView(article: article, serviceLocator: serviceLocator)
                    }
                }
                .refreshable {
                    viewModel.handle(event: .onRefresh)
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
        if viewModel.viewState.isLoading && viewModel.viewState.articles.isEmpty {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showOnboarding {
            onboardingView
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
            Label("Unable to Load Feed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                viewModel.handle(event: .onRefresh)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var onboardingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Personalize Your Feed")
                .font(.title2)
                .fontWeight(.bold)

            Text("Follow topics and sources to see articles tailored to your interests.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink {
                SettingsView(serviceLocator: serviceLocator)
            } label: {
                Label("Set Preferences", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Articles", systemImage: "newspaper")
        } description: {
            Text("No articles found based on your preferences.")
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !viewModel.viewState.followedTopics.isEmpty {
                    followedTopicsBar
                }

                ForEach(viewModel.viewState.articles) { item in
                    ArticleRowView(item: item) {
                        viewModel.handle(event: .onArticleTapped(item.article))
                    } onBookmark: {
                    } onShare: {
                    }
                    .onAppear {
                        if item == viewModel.viewState.articles.last {
                            viewModel.handle(event: .onLoadMore)
                        }
                    }
                }

                if viewModel.viewState.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
        }
    }

    private var followedTopicsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.viewState.followedTopics) { topic in
                    Text(topic.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(topic.color.opacity(0.1))
                        .foregroundStyle(topic.color)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ForYouView(serviceLocator: .preview)
}

struct ForYouCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        ForYouView(serviceLocator: serviceLocator)
    }
}
