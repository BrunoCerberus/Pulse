import Combine
import EntropyCore
import Foundation

final class FeedDomainInteractor: CombineInteractor {
    typealias DomainState = FeedDomainState
    typealias DomainAction = FeedDomainAction

    private let feedService: FeedService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<FeedDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var generationTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<FeedDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: FeedDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            feedService = try serviceLocator.retrieve(FeedService.self)
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve FeedService: \(error)", level: .warning)
            fatalError("FeedService and StorageService are required")
        }

        setupModelStatusBinding()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func dispatch(action: FeedDomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .refresh:
            refresh()
        case let .modelStatusChanged(status):
            handleModelStatusChanged(status)
        case let .readingHistoryLoaded(articles):
            handleHistoryLoaded(articles)
        case let .readingHistoryFailed(error):
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

        // Always clear cache and regenerate fresh
        feedService.clearCache()

        // Fetch reading history
        fetchReadingHistory()
    }

    private func refresh() {
        // Clear the service cache to force regeneration with new prompt
        feedService.clearCache()

        updateState { state in
            state.currentDigest = nil
            state.streamingText = ""
            state.generationState = .idle
        }
        fetchReadingHistory()
    }

    // MARK: - Reading History

    private func fetchReadingHistory() {
        updateState { $0.generationState = .loadingHistory }

        Task { @MainActor in
            do {
                // Filter to articles read in the last 48 hours (by readAt, not publishedAt)
                let cutoff = Date().addingTimeInterval(-48 * 60 * 60)
                let recentHistory = try await storageService.fetchRecentReadingHistory(since: cutoff)
                dispatch(action: .readingHistoryLoaded(recentHistory))
            } catch {
                dispatch(action: .readingHistoryFailed(error.localizedDescription))
            }
        }
    }

    private func handleHistoryLoaded(_ articles: [Article]) {
        updateState { state in
            state.readingHistory = articles
            state.hasLoadedInitialData = true
            state.generationState = articles.isEmpty ? .idle : state.generationState
        }

        // Auto-generate if we have history and no digest
        if !articles.isEmpty, currentState.currentDigest == nil {
            dispatch(action: .generateDigest)
        } else if articles.isEmpty {
            updateState { $0.generationState = .idle }
        }
    }

    // MARK: - Digest Generation

    // swiftlint:disable:next function_body_length
    private func generateDigest() {
        guard !currentState.readingHistory.isEmpty else {
            updateState { $0.generationState = .error("No recent reading history") }
            return
        }

        generationTask?.cancel()

        // Cap articles to prevent context overflow and long generation times
        let articlesToProcess = FeedDigestPromptBuilder.cappedArticles(from: currentState.readingHistory)
        let totalArticles = currentState.readingHistory.count
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
    }
}
