import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("story_threads.title")
    }

    static var emptyTitle: String {
        AppLocalization.localized("story_threads.empty.title")
    }

    static var emptyMessage: String {
        AppLocalization.localized("story_threads.empty.message")
    }

    static var errorTitle: String {
        AppLocalization.localized("story_threads.error.title")
    }

    static var tryAgain: String {
        AppLocalization.localized("common.try_again")
    }

    static var refreshComplete: String {
        AppLocalization.localized("accessibility.refresh_complete")
    }
}

// MARK: - StoryThreadsView

struct StoryThreadsView<R: StoryThreadNavigationRouter>: View {
    private var router: R

    @ObservedObject var viewModel: StoryThreadViewModel

    init(router: R, viewModel: StoryThreadViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .refreshable {
            viewModel.handle(event: .didPullToRefresh)
        }
        .accessibilityIdentifier("storyThreadsView")
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.viewState.errorMessage {
            errorView(message: error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            threadsList
        }
    }

    private var threadsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.viewState.threads) { item in
                    StoryThreadCardView(item: item) {
                        router.route(navigationEvent: .threadDetail(item))
                        viewModel.dispatch(action: .markThreadAsRead(id: item.id))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: IconSize.xxl))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Constants.emptyTitle)
                .font(Typography.titleMedium)
                .bold()
                .accessibilityAddTraits(.isHeader)

            Text(Constants.emptyMessage)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("storyThreadsEmptyState")
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: IconSize.xxl))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Constants.errorTitle)
                .font(Typography.titleMedium)
                .bold()
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.handle(event: .didPullToRefresh)
            } label: {
                Text(Constants.tryAgain)
                    .font(Typography.labelLarge)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}
