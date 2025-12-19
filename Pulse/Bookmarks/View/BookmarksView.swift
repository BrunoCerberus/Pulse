import SwiftUI

struct BookmarksView<R: BookmarksNavigationRouter>: View {
    /// Router responsible for navigation actions
    private var router: R

    /// Backing ViewModel managing data and actions
    @ObservedObject var viewModel: BookmarksViewModel

    /// Creates the view with a router and ViewModel.
    /// - Parameters:
    ///   - router: Navigation router for routing actions
    ///   - viewModel: ViewModel for managing data and actions
    init(router: R, viewModel: BookmarksViewModel) {
        self.router = router
        self.viewModel = viewModel
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
                    router.route(navigationEvent: .articleDetail(article))
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
            router: BookmarksNavigationRouter(),
            viewModel: BookmarksViewModel(serviceLocator: .preview)
        )
    }
}
