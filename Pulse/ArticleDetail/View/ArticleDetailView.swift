import Foundation
import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isContentExpanded = false

    private let serviceLocator: ServiceLocator
    private let heroBaseHeight: CGFloat = 280

    private let contentLineLimit = 4

    private enum ArticleContent {
        case html(String)
        case plain(String)
    }

    /// Strips the "[+XXX chars]" truncation marker from API content
    private var articleContent: ArticleContent? {
        guard let content = article.content else { return nil }
        let strippedContent = stripTruncationMarker(from: content)
        if containsHTML(in: content) {
            return .html(strippedContent)
        }

        let sanitizedContent = plainText(from: strippedContent)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedContent.isEmpty else { return nil }
        return .plain(sanitizedContent)
    }

    private var cleanedDescription: String? {
        guard let description = article.description else { return nil }
        return plainText(from: description)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if the content was truncated by the API
    private var isContentTruncated: Bool {
        guard let content = article.content, !containsHTML(in: content) else { return false }
        return content.contains(#/\[\+\d+ chars\]/#)
    }

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
        .navigationBarTitleDisplayMode(.inline)
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

            if let description = cleanedDescription {
                Text(description)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.primary)
            }

            if let content = articleContent {
                switch content {
                case let .html(html):
                    HTMLTextView(html: html)
                        .fixedSize(horizontal: false, vertical: true)
                case let .plain(text):
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(text)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .lineLimit(isContentTruncated ? (isContentExpanded ? nil : contentLineLimit) : nil)

                        if isContentTruncated {
                            Button {
                                HapticManager.shared.tap()
                                withAnimation(.easeInOut(duration: AnimationTiming.normal)) {
                                    isContentExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: Spacing.xxs) {
                                    Text(isContentExpanded ? "Show less" : "Show more")
                                    Image(systemName: isContentExpanded ? "chevron.up" : "chevron.down")
                                }
                                .font(Typography.labelMedium)
                                .foregroundStyle(Color.Accent.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

    private func plainText(from html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) {
            return attributedString.string
        }

        return html
    }

    private func stripTruncationMarker(from content: String) -> String {
        let pattern = #"\s*\[\+\d+ chars\]"#
        return content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    private func containsHTML(in content: String) -> Bool {
        content.range(of: #"<[^>]+>"#, options: .regularExpression) != nil
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
