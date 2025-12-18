import SwiftUI

struct BookmarksView: View {
    @StateObject private var viewModel: BookmarksViewModel
    @State private var showArticleDetail = false

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: BookmarksViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmarks")
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
        if viewModel.viewState.isLoading {
            ProgressView()
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
        ContentUnavailableView {
            Label("Unable to Load Bookmarks", systemImage: "exclamationmark.triangle")
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
            Label("No Bookmarks", systemImage: "bookmark")
        } description: {
            Text("Articles you bookmark will appear here for offline reading.")
        }
    }

    private var bookmarksList: some View {
        List {
            ForEach(viewModel.viewState.bookmarks) { item in
                ArticleRowView(item: item) {
                    viewModel.handle(event: .onArticleTapped(item.article))
                } onBookmark: {
                    viewModel.handle(event: .onRemoveBookmark(item.article))
                } onShare: {
                }
                .listRowInsets(EdgeInsets())
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let article = viewModel.viewState.bookmarks[index].article
                    viewModel.handle(event: .onRemoveBookmark(article))
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    BookmarksView(serviceLocator: .preview)
}

struct BookmarksCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        BookmarksView(serviceLocator: serviceLocator)
    }
}
