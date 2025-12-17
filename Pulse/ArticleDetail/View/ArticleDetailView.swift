import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(article: Article) {
        self.article = article
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.quaternary)
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .overlay { ProgressView() }
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 250)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(.quaternary)
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let category = article.category {
                        Text(category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        if let author = article.author {
                            Text("By \(author)")
                                .fontWeight(.medium)
                        }

                        Text("•")

                        Text(article.source.name)

                        Text("•")

                        Text(article.formattedDate)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    if let description = article.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    if let content = article.content {
                        Text(content)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Divider()

                    Button {
                        viewModel.openInBrowser()
                    } label: {
                        Label("Read Full Article", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {
                        viewModel.toggleBookmark()
                    } label: {
                        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    }

                    Button {
                        viewModel.share()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = URL(string: article.url) {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article(
                title: "Sample Article Title",
                description: "This is a sample description for the article that provides more context.",
                content: "This is the full content of the article...",
                author: "John Doe",
                source: ArticleSource(id: nil, name: "Sample Source"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/400/300",
                publishedAt: Date(),
                category: .technology
            )
        )
    }
}
