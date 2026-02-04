import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = "Daily Digest"
    static let headerTitle = "Your Daily Digest"
    static let emptyTitle = "No Recent Reading"
    static let emptyMessage = "Read some articles to get your personalized daily digest."
    static let errorTitle = "Something went wrong"
    static let tryAgain = "Try Again"
    static let startReading = "Start Reading"
}

// MARK: - FeedView

/// Feed screen displaying AI-powered daily digests.
///
/// This view gates premium content, showing `PremiumGateView` for non-premium users.
/// For premium users, it displays the AI-generated digest based on their reading history.
///
/// ## Features
/// - Premium status observation via StoreKit
/// - AI digest generation using on-device LLM
/// - Streaming text display during generation
/// - BentoGrid layout for digest content
/// - Empty state when no reading history exists
///
/// - Note: This is a **Premium** feature.
struct FeedView<R: FeedNavigationRouter>: View {
    private var router: R
    private let serviceLocator: ServiceLocator

    @ObservedObject var viewModel: FeedViewModel
    @State private var isPremium = false
    @State private var subscriptionCancellable: AnyCancellable?

    init(router: R, viewModel: FeedViewModel, serviceLocator: ServiceLocator) {
        self.router = router
        self.viewModel = viewModel
        self.serviceLocator = serviceLocator
    }

    private var isProcessing: Bool {
        if case .processing = viewModel.viewState.displayState { return true }
        return false
    }

    var body: some View {
        Group {
            if isPremium {
                premiumContent
            } else {
                PremiumGateView(
                    feature: .dailyDigest,
                    serviceLocator: serviceLocator
                )
                .navigationTitle(Constants.title)
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            observeSubscriptionStatus()
        }
        .onDisappear {
            subscriptionCancellable?.cancel()
        }
    }

    private var premiumContent: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            content
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.viewState.displayState)
        .navigationTitle(isProcessing ? "" : Constants.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(isProcessing ? .hidden : .automatic, for: .navigationBar)
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selectedArticle) { _, article in
            if let article {
                router.route(navigationEvent: .articleDetail(article))
                viewModel.handle(event: .onArticleNavigated)
            }
        }
    }

    private func observeSubscriptionStatus() {
        subscriptionCancellable?.cancel()
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            // Set initial status immediately to avoid UI flicker
            isPremium = storeKitService.isPremium
            // Then observe for changes
            subscriptionCancellable = storeKitService.subscriptionStatusPublisher
                .receive(on: DispatchQueue.main)
                .sink { newStatus in
                    self.isPremium = newStatus
                }
        } catch {
            Logger.error("Failed to retrieve StoreKitService: \(error)")
            isPremium = false
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient.subtleBackground
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState.displayState {
        case .idle, .loading:
            // These states shouldn't occur - digest auto-generates on tab open
            processingView(phase: .generating)
                .transition(.opacity)
        case let .processing(phase):
            processingView(phase: phase)
                .transition(.opacity)
        case .completed:
            digestContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.easeOut(duration: 0.4)),
                    removal: .opacity
                ))
        case .empty:
            emptyStateView
                .transition(.opacity)
        case .error:
            errorView
                .transition(.opacity)
        }
    }

    // MARK: - Processing View

    private func processingView(phase: AIProcessingPhase) -> some View {
        AIProcessingView(
            phase: phase,
            streamingText: viewModel.viewState.streamingText
        )
    }

    // MARK: - Digest Content

    private var digestContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                dateHeader
                    .opacity(viewModel.viewState.digest != nil ? 1 : 0)
                    .offset(y: viewModel.viewState.digest != nil ? 0 : 10)

                if let digest = viewModel.viewState.digest {
                    BentoDigestGrid(
                        digest: digest,
                        sourceArticles: viewModel.viewState.sourceArticles,
                        onArticleTapped: { article in
                            viewModel.handle(event: .onArticleTapped(article.article))
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                    .transition(.asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 0.95))
                            .animation(.easeOut(duration: 0.4)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            FeedEmptyStateView()
                .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            dateHeader

            GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: IconSize.xxl))
                        .foregroundStyle(Color.Semantic.warning)

                    Text(Constants.errorTitle)
                        .font(Typography.titleMedium)

                    if let error = viewModel.viewState.errorMessage {
                        Text(error)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onRetryTapped)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text(Constants.tryAgain)
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .pressEffect()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Constants.headerTitle)
                    .font(Typography.titleLarge)
                Text(viewModel.viewState.headerDate)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
}

#Preview {
    NavigationStack {
        FeedView(
            router: FeedNavigationRouter(),
            viewModel: FeedViewModel(serviceLocator: .preview),
            serviceLocator: .preview
        )
    }
}
