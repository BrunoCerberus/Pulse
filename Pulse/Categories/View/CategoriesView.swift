import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel: CategoriesViewModel
    @State private var showArticleDetail = false

    init(viewModel: CategoriesViewModel = CategoriesViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoriesGrid
                    .padding()

                Divider()

                articlesList
            }
            .navigationTitle("Categories")
            .navigationDestination(isPresented: $showArticleDetail) {
                if let article = viewModel.selectedArticle {
                    ArticleDetailView(article: article)
                }
            }
        }
        .onChange(of: viewModel.selectedArticle) { _, newValue in
            showArticleDetail = newValue != nil
        }
    }

    private var categoriesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(viewModel.viewState.categories) { category in
                CategoryCard(
                    category: category,
                    isSelected: category == viewModel.viewState.selectedCategory
                ) {
                    viewModel.handle(event: .onCategorySelected(category))
                }
            }
        }
    }

    @ViewBuilder
    private var articlesList: some View {
        if viewModel.viewState.selectedCategory == nil {
            ContentUnavailableView {
                Label("Select a Category", systemImage: "square.grid.2x2")
            } description: {
                Text("Choose a category above to see related articles.")
            }
        } else if viewModel.viewState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.viewState.errorMessage {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    viewModel.handle(event: .onRefresh)
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.viewState.showEmptyState {
            ContentUnavailableView {
                Label("No Articles", systemImage: "newspaper")
            } description: {
                Text("No articles found in this category.")
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
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
            .refreshable {
                viewModel.handle(event: .onRefresh)
            }
        }
    }
}

struct CategoryCard: View {
    let category: NewsCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : category.color)

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color : category.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct CategoriesCoordinator {
    static func start() -> some View {
        CategoriesView()
    }
}

#Preview {
    CategoriesView()
}
