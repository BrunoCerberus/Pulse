import SwiftUI

// MARK: - Constants

private enum DigestConstants {
    static let title = String(localized: "digest.title")
    static let emptyTitle = String(localized: "digest.empty.title")
    static let emptySubtitle = String(localized: "digest.empty.subtitle")
}

// MARK: - DigestView

struct DigestView<R: DigestNavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: DigestViewModel

    init(router: R, viewModel: DigestViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(DigestConstants.title)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(message: error)
        } else if viewModel.viewState.isEmpty {
            emptyView
        } else {
            summariesList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.Accent.primary)
            Text("Loading summaries...")
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.Accent.gradient.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            VStack(spacing: Spacing.sm) {
                Text(DigestConstants.emptyTitle)
                    .font(Typography.titleMedium)

                Text(DigestConstants.emptySubtitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Open an article and tap the sparkles button to create a summary")
                .font(Typography.captionLarge)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
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
                viewModel.handle(event: .onRetryTapped)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(Typography.labelMedium)
                .foregroundStyle(Color.Accent.primary)
            }
        }
        .padding(Spacing.xl)
    }

    // MARK: - Summaries List

    private var summariesList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.summaries) { item in
                    DigestSummaryCard(
                        item: item,
                        onTap: {
                            HapticManager.shared.tap()
                            router.route(navigationEvent: .articleDetail(item.article))
                        },
                        onDelete: {
                            HapticManager.shared.warning()
                            viewModel.handle(event: .onDeleteSummary(articleID: item.id))
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .accessibilityIdentifier("digestSummariesList")
    }
}

#Preview {
    NavigationStack {
        DigestView(
            router: DigestNavigationRouter(),
            viewModel: DigestViewModel(serviceLocator: .preview)
        )
    }
}
