import Combine
import Foundation

final class DigestDomainInteractor: CombineInteractor {
    typealias DomainState = DigestDomainState
    typealias DomainAction = DigestDomainAction

    private let digestService: DigestService
    private let llmService: LLMService
    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<DigestDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var generationTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<DigestDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DigestDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            digestService = try serviceLocator.retrieve(DigestService.self)
        } catch {
            Logger.shared.service("Failed to retrieve DigestService: \(error)", level: .warning)
            digestService = LiveDigestService(storageService: LiveStorageService())
        }

        do {
            llmService = try serviceLocator.retrieve(LLMService.self)
        } catch {
            Logger.shared.service("Failed to retrieve LLMService: \(error)", level: .warning)
            llmService = LiveLLMService()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }

        setupBindings()
    }

    private func setupBindings() {
        llmService.modelStatusPublisher
            .sink { [weak self] status in
                self?.updateState { $0.modelStatus = status }
            }
            .store(in: &cancellables)
    }

    func dispatch(action: DigestDomainAction) {
        switch action {
        case .loadModelIfNeeded:
            loadModelIfNeeded()
        case let .selectSource(source):
            selectSource(source)
        case .loadArticlesForSource:
            loadArticlesForSource()
        case .generateDigest:
            generateDigest()
        case .cancelGeneration:
            cancelGeneration()
        case .clearDigest:
            clearDigest()
        case let .updateModelStatus(status):
            updateState { $0.modelStatus = status }
        case .unloadModel:
            unloadModel()
        case .retryGeneration:
            generateDigest()
        }
    }

    // MARK: - Action Handlers

    private func loadModelIfNeeded() {
        guard !llmService.isModelLoaded else { return }

        Task { [weak self] in
            do {
                try await self?.llmService.loadModel()
            } catch {
                await MainActor.run {
                    self?.updateState { state in
                        state.error = .generationFailed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func selectSource(_ source: DigestSource) {
        updateState { state in
            state.selectedSource = source
            state.sourceArticles = []
            state.generatedDigest = nil
            state.error = nil
        }
        loadArticlesForSource()
    }

    private func loadArticlesForSource() {
        guard let source = currentState.selectedSource else { return }

        updateState { $0.isLoadingArticles = true }

        Task { [weak self] in
            guard let self else { return }

            do {
                // Load user preferences for fresh news source
                let preferences = try await storageService.fetchUserPreferences() ?? .default

                await MainActor.run {
                    self.updateState { $0.userPreferences = preferences }
                }

                let articles: [Article]

                switch source {
                case .bookmarks:
                    articles = try await storageService.fetchBookmarkedArticles()

                case .readingHistory:
                    articles = try await storageService.fetchReadingHistory()

                case .freshNews:
                    guard !preferences.followedTopics.isEmpty else {
                        await MainActor.run {
                            self.updateState { state in
                                state.isLoadingArticles = false
                                state.error = .noTopicsConfigured
                            }
                        }
                        return
                    }
                    articles = try await digestService.fetchFreshNews(
                        for: preferences.followedTopics
                    )
                }

                await MainActor.run {
                    self.updateState { state in
                        state.sourceArticles = articles
                        state.isLoadingArticles = false
                        if articles.isEmpty {
                            state.error = .noArticlesAvailable
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateState { state in
                        state.isLoadingArticles = false
                        state.error = .loadingFailed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func generateDigest() {
        guard !currentState.sourceArticles.isEmpty else {
            updateState { $0.error = .noArticlesAvailable }
            return
        }

        guard llmService.isModelLoaded else {
            updateState { $0.error = .modelNotReady }
            loadModelIfNeeded()
            return
        }

        updateState { state in
            state.isGenerating = true
            state.generationProgress = ""
            state.error = nil
        }

        generationTask = Task { [weak self] in
            guard let self else { return }

            let articles = currentState.sourceArticles
            let source = currentState.selectedSource ?? .bookmarks
            let prompt = DigestPromptBuilder.buildPrompt(for: articles, source: source)

            do {
                var fullText = ""

                for try await token in llmService.generateStream(
                    prompt: prompt,
                    config: .default
                ) {
                    if Task.isCancelled { break }
                    fullText += token

                    await MainActor.run {
                        self.updateState { $0.generationProgress = fullText }
                    }
                }

                let result = DigestResult(
                    source: source,
                    content: fullText,
                    articleCount: articles.count,
                    articlesUsed: articles
                )

                await MainActor.run {
                    self.updateState { state in
                        state.generatedDigest = result
                        state.isGenerating = false
                        state.generationProgress = ""
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateState { state in
                        state.isGenerating = false
                        state.error = .generationFailed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        llmService.cancelGeneration()
        updateState { state in
            state.isGenerating = false
            state.generationProgress = ""
        }
    }

    private func clearDigest() {
        updateState { state in
            state.generatedDigest = nil
            state.generationProgress = ""
        }
    }

    private func unloadModel() {
        Task {
            await llmService.unloadModel()
        }
    }

    private func updateState(_ transform: (inout DigestDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    deinit {
        generationTask?.cancel()
    }
}
