import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "summarization.title")
    static let subtitle = String(localized: "summarization.subtitle")
    static let generateButton = String(localized: "summarization.generate")
    static let cancelButton = String(localized: "summarization.cancel")
    static let retryButton = String(localized: "summarization.retry")
    static let doneButton = String(localized: "common.done")
    static let loadingModel = String(localized: "summarization.loading_model")
    static let generating = String(localized: "summarization.generating")
}

// MARK: - SummarizationSheet

struct SummarizationSheet: View {
    let article: Article
    @ObservedObject var viewModel: SummarizationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    contentSection
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Constants.doneButton) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: IconSize.xxl))
                .foregroundStyle(Color.Accent.gradient)
                .symbolEffect(.bounce, options: .repeat(2))

            Text(Constants.subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.state {
        case .idle:
            idleContent
        case let .loadingModel(progress):
            loadingModelContent(progress: progress)
        case .generating:
            generatingContent
        case .completed:
            completedContent
        case let .error(message):
            errorContent(message: message)
        }
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: Spacing.lg) {
            articlePreview

            Button {
                HapticManager.shared.buttonPress()
                viewModel.startSummarization(article: article)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                    Text(Constants.generateButton)
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

    private var articlePreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(article.title)
                .font(Typography.headlineSmall)
                .lineLimit(3)

            HStack(spacing: Spacing.xs) {
                Text(article.source.name)
                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
                Text(article.formattedDate)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Loading Model State

    private func loadingModelContent(progress: Double) -> some View {
        VStack(spacing: Spacing.md) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color.Accent.primary)

            Text(Constants.loadingModel)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)

            Text("\(Int(progress * 100))%")
                .font(Typography.captionLarge)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Generating State

    private var generatingContent: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .tint(Color.Accent.primary)
                Text(Constants.generating)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.generatedSummary.isEmpty {
                Text(viewModel.generatedSummary)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .glassBackground(style: .thin, cornerRadius: CornerRadius.md)
            }

            Button {
                HapticManager.shared.tap()
                viewModel.cancel()
            } label: {
                Text(Constants.cancelButton)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Completed State

    private var completedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.Accent.primary)
                Text("AI Summary")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.Accent.primary)
            }

            Text(viewModel.generatedSummary)
                .font(Typography.bodyMedium)
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Error State

    private func errorContent(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: IconSize.xl))
                .foregroundStyle(.orange)

            Text(message)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.tap()
                viewModel.startSummarization(article: article)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text(Constants.retryButton)
                }
                .font(Typography.labelMedium)
                .foregroundStyle(Color.Accent.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }
}

#Preview {
    SummarizationSheet(
        article: Article.mockArticles[0],
        viewModel: SummarizationViewModel(serviceLocator: .preview)
    )
}
