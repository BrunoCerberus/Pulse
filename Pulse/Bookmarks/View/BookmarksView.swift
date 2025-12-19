import SwiftUI

struct BookmarksView: View {
    @ObservedObject var viewModel: BookmarksViewModel
    let coordinator: Coordinator

    private var router: BookmarksNavigationRouter {
        BookmarksNavigationRouter(coordinator: coordinator)
    }

    var body: some View {
        content
            .navigationTitle("Bookmarks")
            .refreshable {
                viewModel.handle(event: .onRefresh)
            }
            .onAppear {
                viewModel.handle(event: .onAppear)
            }
            .onChange(of: viewModel.selectedArticle) { _, newValue in
                if let article = newValue {
                    router.route(event: .articleDetail(article))
                    viewModel.selectedArticle = nil
                }
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
                } onShare: {}
                    .listRowInsets(EdgeInsets())
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let article = viewModel.viewState.bookmarks[index].article
                    viewModel.handle(event: .onRemoveBookmark(article))
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        BookmarksView(
            viewModel: BookmarksViewModel(serviceLocator: .preview),
            coordinator: Coordinator(serviceLocator: .preview)
        )
    }
}
