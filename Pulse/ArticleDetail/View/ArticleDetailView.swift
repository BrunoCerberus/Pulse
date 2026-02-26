import Combine
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var back: String {
        AppLocalization.shared.localized("common.back")
    }

    static var readFull: String {
        AppLocalization.shared.localized("article.read_full")
    }

    static var summarize: String {
        AppLocalization.shared.localized("summarization.button")
    }

    static var listen: String {
        AppLocalization.shared.localized("tts.button")
    }
}

// MARK: - ArticleDetailView

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let heroBaseHeight: CGFloat = 280
    private let serviceLocator: ServiceLocator

    @State private var isPremium = false
    @State private var isPaywallPresented = false

    init(article: Article, serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(
            article: article,
            serviceLocator: serviceLocator
        ))
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                LinearGradient.subtleBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let imageURL = viewModel.viewState.article.heroImageURL, let url = URL(string: imageURL) {
                            StretchyAsyncImage(
                                url: url,
                                baseHeight: heroBaseHeight,
                                accessibilityLabel: viewModel.viewState.article.title
                            )
                        }

                        contentCard
                    }
                }
                .accessibilityIdentifier("articleDetailScrollView")
            }

            if viewModel.viewState.isTTSPlayerVisible {
                SpeechPlayerBarView(
                    title: viewModel.viewState.article.title,
                    playbackState: viewModel.viewState.ttsPlaybackState,
                    progress: viewModel.viewState.ttsProgress,
                    speedPreset: viewModel.viewState.ttsSpeedPreset,
                    onPlayPause: { viewModel.handle(event: .onTTSPlayPauseTapped) },
                    onStop: { viewModel.handle(event: .onTTSStopTapped) },
                    onSpeedTap: { viewModel.handle(event: .onTTSSpeedTapped) }
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityIdentifier("speechPlayerBar")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.viewState.isTTSPlayerVisible)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(Constants.back, systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("backButton")
                .accessibilityLabel(Constants.back)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button("", systemImage: "speaker.wave.2") {
                        viewModel.handle(event: .onListenTapped)
                    }
                    .accessibilityIdentifier("listenButton")
                    .accessibilityLabel(Constants.listen)
                    .accessibilityHint(AppLocalization.shared.localized("tts.button_hint"))

                    Button("", systemImage: "sparkles") {
                        if isPremium {
                            viewModel.handle(event: .onSummarizeTapped)
                        } else {
                            HapticManager.shared.notification(.warning)
                            isPaywallPresented = true
                        }
                    }
                    .accessibilityIdentifier("summarizeButton")
                    .accessibilityLabel(Constants.summarize)
                    .accessibilityHint(
                        isPremium
                            ? AppLocalization.shared.localized("article_detail.summarize_hint")
                            : AppLocalization.shared.localized("article_detail.premium_hint")
                    )

                    Button("", systemImage: viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark") {
                        viewModel.handle(event: .onBookmarkTapped)
                    }
                    .accessibilityIdentifier(viewModel.viewState.isBookmarked ? "bookmark.fill" : "bookmark")
                    .accessibilityLabel(
                        viewModel.viewState.isBookmarked
                            ? AppLocalization.shared.localized("article_detail.remove_bookmark")
                            : AppLocalization.shared.localized("article_detail.add_bookmark")
                    )
                    .accessibilityHint(AppLocalization.shared.localized("article_detail.save_hint"))

                    Button("", systemImage: "square.and.arrow.up") {
                        viewModel.handle(event: .onShareTapped)
                    }
                    .accessibilityIdentifier("square.and.arrow.up")
                    .accessibilityLabel(AppLocalization.shared.localized("article_detail.share_label"))
                    .accessibilityHint(AppLocalization.shared.localized("article_detail.share_hint"))
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showShareSheet },
            set: { if !$0 { viewModel.handle(event: .onShareSheetDismissed) } }
        )) {
            if let url = URL(string: viewModel.viewState.article.url) {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showSummarizationSheet },
            set: { if !$0 { viewModel.handle(event: .onSummarizationSheetDismissed) } }
        )) {
            SummarizationSheet(
                viewModel: SummarizationViewModel(
                    article: viewModel.viewState.article,
                    serviceLocator: serviceLocator
                )
            )
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
            initializeSubscriptionStatus()
        }
        .onDisappear {
            viewModel.handle(event: .onDisappear)
        }
        .onReceive(subscriptionStatusPublisher) { newStatus in
            isPremium = newStatus
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: paywallViewModel) }
        )
        .onChange(of: viewModel.viewState.isBookmarked) { _, isBookmarked in
            let announcement = isBookmarked
                ? AppLocalization.shared.localized("accessibility.bookmark_added")
                : AppLocalization.shared.localized("accessibility.bookmark_removed")
            AccessibilityNotification.Announcement(announcement).post()
        }
        .onChange(of: viewModel.viewState.ttsPlaybackState) { _, newState in
            let announcement: String? = switch newState {
            case .playing:
                AppLocalization.shared.localized("accessibility.tts_started")
            case .paused:
                AppLocalization.shared.localized("accessibility.tts_paused")
            case .idle:
                nil
            }
            if let announcement {
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
        .enableSwipeBack()
    }

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
        }
    }

    private var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        guard let storeKitService = try? serviceLocator.retrieve(StoreKitService.self) else {
            return Empty().eraseToAnyPublisher()
        }
        return storeKitService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func initializeSubscriptionStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            Logger.shared.warning("Failed to retrieve StoreKitService: \(error)", category: "ArticleDetail")
            isPremium = false
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
    .preferredColorScheme(.dark)
}
