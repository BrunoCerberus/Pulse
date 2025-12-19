import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isContentExpanded = false

    private let serviceLocator: ServiceLocator

    /// Strips the "[+XXX chars]" truncation marker from API content
    private var cleanedContent: String? {
        guard let content = article.content else { return nil }
        let pattern = #"\s*\[\+\d+ chars\]$"#
        return content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    /// Checks if the content was truncated by the API
    private var isContentTruncated: Bool {
        guard let content = article.content else { return false }
        return content.contains(#/\[\+\d+ chars\]/#)
    }

    init(article: Article, serviceLocator: ServiceLocator) {
        self.article = article
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article, serviceLocator: serviceLocator))
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
                                .frame(maxWidth: .infinity, maxHeight: 250)
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

                    HStack(spacing: 4) {
                        if let author = article.author {
                            Text("By \(author)")
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .layoutPriority(-1)
                        }

                        Text("•")

                        Text(article.source.name)
                            .lineLimit(1)

                        Text("•")

                        Text(article.formattedDate)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    if let description = article.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    if let content = cleanedContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(content)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(isContentExpanded ? nil : 4)

                            if isContentTruncated {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isContentExpanded.toggle()
                                    }
                                } label: {
                                    Text(isContentExpanded ? "Show less" : "Show more")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
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
            article: Article.mockArticles[0],
            serviceLocator: .preview
        )
    }
}
