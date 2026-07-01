import Combine
import EntropyCore
import Foundation

/// Domain interactor for the Feed (AI Daily Digest) feature.
///
/// Manages business logic and state for AI-powered digest generation, including:
/// - Loading the latest news articles from the API by category
/// - On-device LLM model lifecycle (preload, load, generate)
/// - Streaming text generation with token batching
/// - Digest caching and retrieval
///
/// ## Data Flow
/// 1. Views dispatch `FeedDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `FeedDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `FeedService`: Manages LLM model and digest generation
/// - `NewsService`: Fetches latest articles from the API
///
/// - Note: This is a **Premium** feature.
final class FeedDomainInteractor: CombineInteractor {
    typealias DomainState = FeedDomainState
    typealias DomainAction = FeedDomainAction

    private let feedService: FeedService
    private let newsService: NewsService
    private let networkMonitor: NetworkMonitorService?
    private let analyticsService: AnalyticsService?
    /// Used for a defense-in-depth Premium re-check at the service boundary.
    /// Optional so previews / unit tests that don't register StoreKit aren't gated.
    private let storeKitService: StoreKitService?
    /// Personalizes the audio-briefing queue. Optional: when missing or when
    /// it returns nothing, the briefing falls back to digest-only.
    private let forYouService: ForYouService?
    /// Global playback queue that runs the audio briefing.
    private let playbackQueueService: PlaybackQueueService?
    /// Cache of today's opportunistically pre-generated Morning Briefing,
    /// written by `MorningBriefingPrefetcher`. Optional: when missing, the
    /// scheduled briefing falls back to on-demand generation.
    private let briefingCacheService: BriefingCacheService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var generationTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?
    private var fetchArticlesTask: Task<Void, Never>?
    private var briefingTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            feedService = try serviceLocator.retrieve(FeedService.self)
            newsService = try serviceLocator.retrieve(NewsService.self)
        } catch {
            fatalError("FeedDomainInteractor requires FeedService and NewsService: \(error)")
        }

        networkMonitor = try? serviceLocator.retrieve(NetworkMonitorService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
        storeKitService = try? serviceLocator.retrieve(StoreKitService.self)
        forYouService = try? serviceLocator.retrieve(ForYouService.self)
        playbackQueueService = try? serviceLocator.retrieve(PlaybackQueueService.self)
        briefingCacheService = try? serviceLocator.retrieve(BriefingCacheService.self)

        setupModelStatusBinding()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func dispatch(action: DomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .preloadModel:
            preloadModel()
        case let .modelStatusChanged(status):
            handleModelStatusChanged(status)
        case let .latestArticlesLoaded(articles):
            handleArticlesLoaded(articles)
        case let .latestArticlesFailed(error, isOffline):
            updateState { state in
                state.generationState = .error(error)
                state.isOfflineError = isOffline
            }
        case .generateDigest:
            generateDigest()
        case .startAudioBriefing:
            startAudioBriefing()
        case .startMorningBriefing:
            startMorningBriefing()
        case let .digestTokenReceived(token):
            updateState { $0.streamingText += token }
        case let .digestCompleted(digest):
            handleDigestCompleted(digest)
        case let .digestFailed(error):
            analyticsService?.logEvent(.digestGenerated(success: false))
            let digestError = NSError(domain: "FeedDigest", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            analyticsService?.recordError(digestError)
            updateState { state in
                state.generationState = .error(error)
            }
        case let .selectArticle(article):
            updateState { $0.selectedArticle = article }
        case .clearSelectedArticle:
            updateState { $0.selectedArticle = nil }
        case let .generationStateChanged(newState):
            updateState { $0.generationState = newState }
        case .clearError:
            updateState { state in
                if case .error = state.generationState {
                    state.generationState = .idle
                }
                state.isOfflineError = false
            }
        case .retryAfterError:
            updateState { state in
                state.hasLoadedInitialData = false
                state.isOfflineError = false
                state.generationState = .loadingArticles
            }
            fetchLatestNews()
        }
    }

    // MARK: - Setup

    private func setupModelStatusBinding() {
        feedService.modelStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.dispatch(action: .modelStatusChanged(status))
            }
            .store(in: &cancellables)
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    deinit {
        generationTask?.cancel()
        preloadTask?.cancel()
        fetchArticlesTask?.cancel()
        briefingTask?.cancel()
    }
}

// MARK: - Feed Initial Load

private extension FeedDomainInteractor {
    func loadInitialData() {
        guard !currentState.hasLoadedInitialData else { return }

        analyticsService?.logEvent(.screenView(screen: .feed))

        // Always show processing animation first for consistent UX
        updateState { $0.generationState = .loadingArticles }

        // Check for cached digest first
        if let cachedDigest = feedService.fetchTodaysDigest() {
            // Brief delay to ensure animation is visible before showing cached content
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                updateState { state in
                    state.currentDigest = cachedDigest
                    state.latestArticles = cachedDigest.sourceArticles
                    state.hasLoadedInitialData = true
                    state.generationState = .completed
                }
            }
            return
        }

        // No cached digest - preload model in background while fetching articles
        // This parallelizes model loading with article fetch for faster generation
        preloadModel()

        // Fetch latest news articles if no cached digest
        fetchLatestNews()
    }

    func preloadModel() {
        // Skip if preload already in progress (task-based synchronization)
        guard preloadTask == nil else { return }

        let service = UncheckedSendableBox(value: feedService)
        preloadTask = Task { @MainActor [weak self] in
            defer { self?.preloadTask = nil }
            do {
                try await service.value.loadModelIfNeeded()
            } catch {
                // Preloading failure is non-fatal; generation will retry loading
                Logger.shared.debug(
                    "Model preload failed (will retry on generation): \(error)",
                    category: "FeedDomainInteractor"
                )
            }
        }
    }

    func fetchLatestNews() {
        fetchArticlesTask?.cancel()
        updateState { $0.generationState = .loadingArticles }

        let newsService = UncheckedSendableBox(value: self.newsService)

        fetchArticlesTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.fetchArticlesTask = nil }

            let allArticles = await FeedArticlePoolBuilder.fetchPool(
                newsService: newsService.value,
                language: AppLocalization.shared.language
            )
            guard !Task.isCancelled else { return }

            if allArticles.isEmpty {
                let isOffline = self.networkMonitor?.isConnected == false
                let message = isOffline
                    ? "You're offline. Connect to the internet to generate your daily digest."
                    : "Unable to fetch news"
                self.dispatch(action: .latestArticlesFailed(message, isOffline: isOffline))
            } else {
                self.dispatch(action: .latestArticlesLoaded(allArticles))
            }
        }
    }

    func handleArticlesLoaded(_ articles: [Article]) {
        updateState { state in
            state.latestArticles = articles
            state.hasLoadedInitialData = true
            state.isOfflineError = false
            state.generationState = articles.isEmpty ? .idle : state.generationState
        }

        // Auto-generate if we have articles and no digest
        if !articles.isEmpty, currentState.currentDigest == nil {
            dispatch(action: .generateDigest)
        } else if articles.isEmpty {
            updateState { $0.generationState = .idle }
        }
    }
}

// MARK: - Feed Digest Generation

private extension FeedDomainInteractor {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func generateDigest() {
        // Defense-in-depth: re-verify the Premium entitlement at the service
        // boundary, not just in the view layer. The digest UI sits behind a
        // Premium gate, but a tampered client could dispatch `.generateDigest`
        // directly. No-op when no StoreKit service is registered (previews /
        // unit tests).
        guard storeKitService?.isPremium != false else {
            Logger.shared.service(
                "Digest generation blocked: Premium entitlement not active",
                level: .warning
            )
            return
        }

        guard !currentState.latestArticles.isEmpty else {
            updateState { $0.generationState = .error("No articles available") }
            return
        }

        generationTask?.cancel()

        // Cap articles to prevent context overflow and long generation times
        let articlesToProcess = FeedDigestPromptBuilder.cappedArticles(from: currentState.latestArticles)
        let totalArticles = currentState.latestArticles.count
        let cappedCount = articlesToProcess.count

        if totalArticles > cappedCount {
            Logger.shared.info(
                "Digest: capped articles from \(totalArticles) to \(cappedCount) for context safety",
                category: "FeedDomainInteractor"
            )
        }

        updateState { state in
            state.streamingText = ""
            state.generationState = .generating
        }

        let feedServiceBox = UncheckedSendableBox(value: feedService)
        generationTask = Task { @MainActor in
            do {
                // Ensure model is loaded
                try await feedServiceBox.value.loadModelIfNeeded()

                guard !Task.isCancelled else { return }

                // Generate digest with streaming
                var fullText = ""
                var tokensSinceLastUpdate = 0
                let updateBatchSize = 3

                for try await token in feedServiceBox.value.generateDigest(from: articlesToProcess) {
                    guard !Task.isCancelled else { break }

                    fullText += token
                    tokensSinceLastUpdate += 1

                    // Update UI with cleaned text during streaming
                    if tokensSinceLastUpdate >= updateBatchSize {
                        let currentText = Self.cleanLLMOutput(fullText)
                        await MainActor.run { [weak self] in
                            self?.updateState { $0.streamingText = currentText }
                        }
                        tokensSinceLastUpdate = 0
                    }
                }

                guard !Task.isCancelled else { return }

                // Create and save digest
                let finalSummary = Self.cleanLLMOutput(fullText)

                // Log generation result for debugging
                Logger.shared.info(
                    "Digest generation: raw=\(fullText.count) chars, cleaned=\(finalSummary.count) chars",
                    category: "FeedDomainInteractor"
                )
                #if DEBUG
                    // Log first 500 chars of output for debugging parsing issues
                    Logger.shared.debug(
                        "Digest output preview: \(String(finalSummary.prefix(500)))",
                        category: "FeedDomainInteractor"
                    )
                #endif

                // Validate that we got a non-empty summary
                guard !finalSummary.isEmpty else {
                    Logger.shared.warning(
                        "Empty digest after cleaning. Raw output: \(fullText.prefix(200))",
                        category: "FeedDomainInteractor"
                    )
                    dispatch(action: .digestFailed("Unable to generate summary. Please try again."))
                    return
                }

                let digest = DailyDigest(
                    id: UUID().uuidString,
                    summary: finalSummary,
                    sourceArticles: articlesToProcess,
                    generatedAt: .now
                )
                feedServiceBox.value.saveDigest(digest)
                dispatch(action: .digestCompleted(digest))

            } catch {
                guard !Task.isCancelled else { return }
                Logger.shared.error(
                    "Digest generation failed: \(error)",
                    category: "FeedDomainInteractor"
                )
                dispatch(action: .digestFailed(error.localizedDescription))
            }
        }
    }

    func handleDigestCompleted(_ digest: DailyDigest) {
        analyticsService?.logEvent(.digestGenerated(success: true))
        updateState { state in
            state.currentDigest = digest
            state.streamingText = ""
            state.generationState = .completed
        }

        if currentState.autoPlayBriefingOnCompletion {
            updateState { $0.autoPlayBriefingOnCompletion = false }
            startAudioBriefing()
        }
    }
}

// MARK: - Audio Briefing

private extension FeedDomainInteractor {
    /// Entry point for the scheduled Morning Briefing (deeplink from the
    /// local notification, or a manual replay of it). Plays instantly from
    /// whatever digest is already available — either this session's
    /// `currentDigest` or a same-day pre-generated cache — and only falls
    /// back to a fresh on-demand generation when neither exists.
    func startMorningBriefing() {
        guard storeKitService?.isPremium != false else {
            Logger.shared.service(
                "Morning Briefing blocked: Premium entitlement not active",
                level: .warning
            )
            return
        }

        // Already has a digest this session (e.g. the Feed tab was visited
        // earlier today) — play immediately, no need to consult the cache.
        if currentState.currentDigest != nil {
            startAudioBriefing()
            return
        }

        if let cached = briefingCacheService?.fetchIfFreshToday() {
            updateState { state in
                state.currentDigest = cached.digest
                state.latestArticles = cached.queueArticles
                state.hasLoadedInitialData = true
                state.generationState = .completed
            }
            playCachedBriefing(cached)
            return
        }

        // No digest anywhere: fetch fresh articles directly (bypassing
        // `loadInitialData()`'s `hasLoadedInitialData` guard, since we've
        // already established above that there's no usable digest to show)
        // and let the existing auto-generate-on-load path
        // (`handleArticlesLoaded` → `.generateDigest`) kick off generation.
        // `handleDigestCompleted` auto-plays once it finishes.
        updateState { $0.autoPlayBriefingOnCompletion = true }
        preloadModel()
        fetchLatestNews()
    }

    /// Plays a pre-generated briefing's exact queue directly, skipping
    /// `startAudioBriefing()`'s ForYou re-scoring — `cached.queueArticles`
    /// is already the final, ranked selection `MorningBriefingPrefetcher`
    /// computed. Re-scoring it again against whatever the profile looks
    /// like *now* could reorder or drop items relative to what was
    /// prepared, and is wasted work for a queue that's already final.
    func playCachedBriefing(_ cached: PregeneratedBriefing) {
        guard let playbackQueueService else { return }
        let language = AppLocalization.shared.language
        let digestItem = PlaybackItem.digest(cached.digest, language: language)
        let articleItems = cached.queueArticles.map { PlaybackItem.article($0, language: language) }
        playbackQueueService.play(items: [digestItem] + articleItems, mode: .briefing)
    }

    /// Assembles the Premium audio briefing and hands it to the global
    /// playback queue: digest narration first, then the top For You articles
    /// scored from the same pool the digest was built from. Falls back to a
    /// digest-only queue when personalization yields nothing (new users,
    /// scoring errors), so the button always produces audio.
    func startAudioBriefing() {
        // Defense-in-depth: same service-boundary Premium re-check as
        // `generateDigest()` — the Feed UI is gated, but a tampered client
        // could dispatch the action directly.
        guard storeKitService?.isPremium != false else {
            Logger.shared.service(
                "Audio briefing blocked: Premium entitlement not active",
                level: .warning
            )
            return
        }

        // The listen button only renders with a completed digest; guard anyway.
        guard let digest = currentState.currentDigest else { return }
        guard let playbackQueueService else { return }

        let pool = currentState.latestArticles.filter { !$0.isMedia }
        let forYouBox = UncheckedSendableBox(value: forYouService)
        let playbackBox = UncheckedSendableBox(value: playbackQueueService)

        briefingTask?.cancel()
        briefingTask = Task { @MainActor [weak self] in
            let language = AppLocalization.shared.language
            let digestItem = PlaybackItem.digest(digest, language: language)

            var articleItems: [PlaybackItem] = []
            if let forYouService = forYouBox.value {
                let scored = (try? await forYouService.scoredArticles(from: pool, topN: 10)) ?? []
                articleItems = scored.map { PlaybackItem.article($0.article, language: language) }
            }

            guard self != nil, !Task.isCancelled else { return }
            playbackBox.value.play(items: [digestItem] + articleItems, mode: .briefing)
        }
    }
}

// MARK: - Feed Helpers

private extension FeedDomainInteractor {
    func handleModelStatusChanged(_ status: LLMModelStatus) {
        updateState { state in
            state.modelStatus = status
            if case let .error(message) = status {
                state.generationState = .error(message)
            }
        }
    }
}
