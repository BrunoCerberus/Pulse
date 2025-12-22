import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private let serviceLocator: ServiceLocator
    private let heroBaseHeight: CGFloat = 280

    init(article: Article, serviceLocator: ServiceLocator) {
        self.article = article
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article, serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                        StretchyAsyncImage(url: url, baseHeight: heroBaseHeight)
                    }

                    contentCard
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemImage: "chevron.left") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button("", systemImage: viewModel.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.toggleBookmark()
                    }

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.share()
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

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let category = article.category {
                GlassCategoryChip(category: category, style: .medium, showIcon: true)
                    .glowEffect(color: category.color, radius: 6)
            }

            Text(article.title)
                .font(Typography.displaySmall)

            metadataRow

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            if let description = article.description {
                Text(description)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.primary)
            }

            if let content = viewModel.processedContent {
                switch content {
                case let .html(html):
                    // Temporarily show as plain text to debug
                    Text(html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                case let .plain(text):
                    Text(text)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .lineLimit(viewModel.isContentTruncated ? (viewModel.isContentExpanded ? nil : viewModel.contentLineLimit) : nil)
                }
            }

            Rectangle()
                .fill(Color.Border.adaptive(for: colorScheme))
                .frame(height: 0.5)

            readFullArticleButton
        }
        .padding(Spacing.lg)
        .background(.regularMaterial)
        .clipShape(
            .rect(
                topLeadingRadius: CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.xl
            )
        )
        .offset(y: -Spacing.lg)
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            if let author = article.author {
                Text("By \(author)")
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)

                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
            }

            Text(article.source.name)
                .lineLimit(1)

            Circle()
                .fill(.secondary)
                .frame(width: 3, height: 3)

            Text(article.formattedDate)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .font(Typography.captionLarge)
        .foregroundStyle(.secondary)
    }

    private var readFullArticleButton: some View {
        Button {
            HapticManager.shared.buttonPress()
            viewModel.openInBrowser()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "safari.fill")
                Text("Read Full Article")
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.Accent.gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        }
        .pressEffect()
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
