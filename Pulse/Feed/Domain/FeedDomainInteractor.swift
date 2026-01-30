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
    private let stateSubject = CurrentValueSubject<FeedDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var generationTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<FeedDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: FeedDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            feedService = try serviceLocator.retrieve(FeedService.self)
            newsService = try serviceLocator.retrieve(NewsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve required services: \(error)", level: .warning)
            fatalError("FeedService and NewsService are required")
        }

        setupModelStatusBinding()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func dispatch(action: FeedDomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .preloadModel:
            preloadModel()
        case let .modelStatusChanged(status):
            handleModelStatusChanged(status)
        case let .latestArticlesLoaded(articles):
            handleArticlesLoaded(articles)
        case let .latestArticlesFailed(error):
            updateState { state in
                state.generationState = .error(error)
            }
        case .generateDigest:
            generateDigest()
        case let .digestTokenReceived(token):
            updateState { $0.streamingText += token }
        case let .digestCompleted(digest):
            handleDigestCompleted(digest)
        case let .digestFailed(error):
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
            }
        }
    }

    // MARK: - Setup

    private func setupModelStatusBinding() {
        feedService.modelStatusPublisher
            .sink { [weak self] status in
                self?.dispatch(action: .modelStatusChanged(status))
            }
            .store(in: &cancellables)
    }

    // MARK: - Initial Load

    private func loadInitialData() {
        guard !currentState.hasLoadedInitialData else { return }

        // Check for cached digest first
        if let cachedDigest = feedService.fetchTodaysDigest() {
            updateState { state in
                state.currentDigest = cachedDigest
                state.latestArticles = cachedDigest.sourceArticles
                state.hasLoadedInitialData = true
                state.generationState = .completed
            }
            return
        }

        // No cached digest - preload model in background while fetching articles
        // This parallelizes model loading with article fetch for faster generation
        preloadModel()

        // Fetch latest news articles if no cached digest
        fetchLatestNews()
    }

    // MARK: - Model Preloading

    private func preloadModel() {
        // Skip if preload already in progress (task-based synchronization)
        guard preloadTask == nil else { return }

        preloadTask = Task { @MainActor [weak self] in
            defer { self?.preloadTask = nil }
            do {
                try await self?.feedService.loadModelIfNeeded()
            } catch {
                // Preloading failure is non-fatal; generation will retry loading
                Logger.shared.debug(
                    "Model preload failed (will retry on generation): \(error)",
                    category: "FeedDomainInteractor"
                )
            }
        }
    }

    // MARK: - Fetch Latest News

    private func fetchLatestNews() {
        updateState { $0.generationState = .loadingArticles }

        // Capture newsService on MainActor before entering task group
        let newsService = self.newsService

        Task { @MainActor in
            var allArticles: [Article] = []

            // Fetch 10 articles from each category in parallel
            await withTaskGroup(of: [Article].self) { group in
                for category in NewsCategory.allCases {
                    group.addTask {
                        do {
                            // Convert Combine publisher to async
                            let articles = try await withCheckedThrowingContinuation { continuation in
                                var cancellable: AnyCancellable?
                                cancellable = newsService
                                    .fetchTopHeadlines(category: category, country: "us", page: 1)
                                    .first()
                                    .sink(
                                        receiveCompletion: { completion in
                                            if case let .failure(error) = completion {
                                                continuation.resume(throwing: error)
                                            }
                                            cancellable?.cancel()
                                        },
                                        receiveValue: { articles in
                                            continuation.resume(returning: articles)
                                        }
                                    )
                            }
                            // Take first 10 articles from this category
                            return Array(articles.prefix(10))
                        } catch {
                            Logger.shared.warning(
                                "Failed to fetch \(category.displayName): \(error)",
                                category: "FeedDomainInteractor"
                            )
                            return [] // Continue with other categories
                        }
                    }
                }

                for await articles in group {
                    allArticles.append(contentsOf: articles)
                }
            }

            // Sort by publishedAt (most recent first) - capping happens in generateDigest()
            allArticles.sort { $0.publishedAt > $1.publishedAt }

            if allArticles.isEmpty {
                dispatch(action: .latestArticlesFailed("Unable to fetch news"))
            } else {
                dispatch(action: .latestArticlesLoaded(allArticles))
            }
        }
    }

    private func handleArticlesLoaded(_ articles: [Article]) {
        updateState { state in
            state.latestArticles = articles
            state.hasLoadedInitialData = true
            state.generationState = articles.isEmpty ? .idle : state.generationState
        }

        // Auto-generate if we have articles and no digest
        if !articles.isEmpty, currentState.currentDigest == nil {
            dispatch(action: .generateDigest)
        } else if articles.isEmpty {
            updateState { $0.generationState = .idle }
        }
    }

    // MARK: - Digest Generation

    // swiftlint:disable:next function_body_length
    private func generateDigest() {
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

        generationTask = Task { @MainActor in
            do {
                // Ensure model is loaded
                try await feedService.loadModelIfNeeded()

                guard !Task.isCancelled else { return }

                // Generate digest with streaming
                var fullText = ""
                var tokensSinceLastUpdate = 0
                let updateBatchSize = 3

                for try await token in feedService.generateDigest(from: articlesToProcess) {
                    guard !Task.isCancelled else { break }

                    fullText += token
                    tokensSinceLastUpdate += 1

                    // Update UI with cleaned text during streaming
                    if tokensSinceLastUpdate >= updateBatchSize {
                        let currentText = cleanLLMOutput(fullText)
                        await MainActor.run { [weak self] in
                            self?.updateState { $0.streamingText = currentText }
                        }
                        tokensSinceLastUpdate = 0
                    }
                }

                guard !Task.isCancelled else { return }

                // Create and save digest
                let finalSummary = cleanLLMOutput(fullText)

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
                    generatedAt: Date()
                )
                feedService.saveDigest(digest)
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

    private func handleDigestCompleted(_ digest: DailyDigest) {
        updateState { state in
            state.currentDigest = digest
            state.generationState = .completed
        }
    }

    // MARK: - Model Status

    private func handleModelStatusChanged(_ status: LLMModelStatus) {
        updateState { state in
            state.modelStatus = status
            if case let .error(message) = status {
                state.generationState = .error(message)
            }
        }
    }

    // MARK: - Helpers

    private nonisolated func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove null characters (LLM sometimes outputs these between tokens)
        cleaned = cleaned.replacingOccurrences(of: "\0", with: "")

        // Remove chat template markers
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "</s>", "<s>", "<|eot_id|>", "<|start_header_id|>", "<|end_header_id|>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = ["here's the digest:", "here is the digest:", "digest:", "here's your daily digest:"]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes where lowercased.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateState(_ transform: (inout FeedDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    deinit {
        generationTask?.cancel()
        preloadTask?.cancel()
    }
}
