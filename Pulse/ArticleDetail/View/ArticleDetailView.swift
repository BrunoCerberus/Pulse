import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isContentExpanded = false

    private let serviceLocator: ServiceLocator
    private let heroBaseHeight: CGFloat = 280

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
        ZStack(alignment: .top) {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .global).minY
                        let stretchAmount = max(0, minY)

                        stickyHeroImage(stretchAmount: stretchAmount)
                            .offset(y: -minY)
                    }
                    .frame(height: heroBaseHeight)

                    contentCard
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .coordinateSpace(name: "articleDetailScroll")

            overlayButtons
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = URL(string: article.url) {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var overlayButtons: some View {
        GeometryReader { _ in
            HStack {
                Button {
                    HapticManager.shared.tap()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: IconSize.sm, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }

                Spacer()

                HStack(spacing: Spacing.sm) {
                    Button {
                        HapticManager.shared.tap()
                        viewModel.toggleBookmark()
                    } label: {
                        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: IconSize.sm))
                            .foregroundStyle(viewModel.isBookmarked ? Color.Accent.primary : .white)
                            .symbolEffect(.bounce, value: viewModel.isBookmarked)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }

                    Button {
                        HapticManager.shared.tap()
                        viewModel.share()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: IconSize.sm))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xxl)
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func stickyHeroImage(stretchAmount: CGFloat) -> some View {
        if let imageURL = article.imageURL, let url = URL(string: imageURL) {
            let scale = 1 + (stretchAmount / heroBaseHeight)

            ZStack(alignment: .bottom) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.primary.opacity(0.05))
                            .overlay { ProgressView() }
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(scale)
                    case .failure:
                        Rectangle()
                            .fill(Color.primary.opacity(0.05))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: IconSize.xxl))
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        Rectangle()
                            .fill(Color.primary.opacity(0.05))
                    }
                }
                .frame(height: heroBaseHeight + stretchAmount)
                .frame(maxWidth: .infinity)

                LinearGradient.heroOverlay
                    .frame(height: 120)
            }
            .frame(height: heroBaseHeight + stretchAmount)
            .frame(maxWidth: .infinity)
            .clipped()
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

            if let content = cleanedContent {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(content)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .lineLimit(isContentExpanded ? nil : 4)

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
