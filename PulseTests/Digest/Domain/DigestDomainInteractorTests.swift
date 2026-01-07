import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("DigestDomainInteractor Tests")
@MainActor
struct DigestDomainInteractorTests {
    let mockLLMService: MockLLMService
    let mockDigestService: MockDigestService
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let sut: DigestDomainInteractor

    init() {
        mockLLMService = MockLLMService()
        mockDigestService = MockDigestService()
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(LLMService.self, instance: mockLLMService)
        serviceLocator.register(DigestService.self, instance: mockDigestService)
        serviceLocator.register(StorageService.self, instance: mockStorageService)

        sut = DigestDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.selectedSource == nil)
        #expect(state.sourceArticles.isEmpty)
        #expect(!state.isLoadingArticles)
        #expect(!state.isGenerating)
        #expect(state.generatedDigest == nil)
        #expect(state.error == nil)
        #expect(state.generationProgress.isEmpty)
    }

    // MARK: - Source Selection Tests

    @Test("Select source sets selected source")
    func selectSourceSetsSelectedSource() async throws {
        sut.dispatch(action: .selectSource(.bookmarks))

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.selectedSource == .bookmarks)
    }

    @Test("Select bookmarks source loads bookmarked articles")
    func selectBookmarksLoadsBookmarkedArticles() async throws {
        let mockArticles = Article.mockArticles
        mockStorageService.mockBookmarkedArticles = mockArticles

        sut.dispatch(action: .selectSource(.bookmarks))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedSource == .bookmarks)
        #expect(!state.isLoadingArticles)
        #expect(state.sourceArticles.count == mockArticles.count)
    }

    @Test("Select reading history source loads history articles")
    func selectReadingHistoryLoadsHistoryArticles() async throws {
        let mockArticles = Article.mockArticles
        mockStorageService.mockReadingHistory = mockArticles

        sut.dispatch(action: .selectSource(.readingHistory))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedSource == .readingHistory)
        #expect(!state.isLoadingArticles)
        #expect(state.sourceArticles.count == mockArticles.count)
    }

    @Test("Select fresh news source loads fresh articles")
    func selectFreshNewsLoadsFreshArticles() async throws {
        let mockArticles = Article.mockArticles
        mockDigestService.freshNewsResult = .success(mockArticles)
        mockStorageService.mockUserPreferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .selectSource(.freshNews))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(state.selectedSource == .freshNews)
        #expect(!state.isLoadingArticles)
        #expect(!state.sourceArticles.isEmpty)
    }

    @Test("Select fresh news with no topics shows error")
    func selectFreshNewsNoTopicsShowsError() async throws {
        mockStorageService.mockUserPreferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        sut.dispatch(action: .selectSource(.freshNews))

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        #expect(!state.isLoadingArticles)
        #expect(state.error == .noTopicsConfigured)
    }

    @Test("Select source clears previous digest")
    func selectSourceClearsPreviousDigest() async throws {
        // Setup: generate a digest first
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        #expect(sut.currentState.generatedDigest != nil)

        // Act: select different source
        sut.dispatch(action: .selectSource(.readingHistory))
        try await Task.sleep(nanoseconds: 100_000_000)

        // Assert: digest should be cleared
        #expect(sut.currentState.generatedDigest == nil)
    }

    @Test("Select source sets loading state")
    func selectSourceSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoadingArticles)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .selectSource(.bookmarks))

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }

    // MARK: - Load Model Tests

    @Test("Load model updates model status")
    func loadModelUpdatesStatus() async throws {
        var cancellables = Set<AnyCancellable>()
        var statusUpdates: [LLMModelStatus] = []

        sut.statePublisher
            .map(\.modelStatus)
            .sink { status in
                statusUpdates.append(status)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadModelIfNeeded)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(statusUpdates.contains { if case .loading = $0 { return true }; return false })
        #expect(statusUpdates.last == .ready)
    }

    @Test("Load model handles memory pressure error")
    func loadModelHandlesMemoryPressure() async throws {
        mockLLMService.shouldSimulateMemoryPressure = true

        sut.dispatch(action: .loadModelIfNeeded)

        try await Task.sleep(nanoseconds: 500_000_000)

        let state = sut.currentState
        if case .error = state.modelStatus {
            // Expected
        } else {
            Issue.record("Expected model status to be error")
        }
    }

    // MARK: - Generate Digest Tests

    @Test("Generate digest requires articles")
    func generateDigestRequiresArticles() async throws {
        await loadModelAndWait()

        sut.dispatch(action: .generateDigest)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.error == .noArticlesAvailable)
    }

    @Test("Generate digest requires loaded model")
    func generateDigestRequiresLoadedModel() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.error == .modelNotReady)
    }

    @Test("Generate digest produces result")
    func generateDigestProducesResult() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let state = sut.currentState
        #expect(!state.isGenerating)
        #expect(state.generatedDigest != nil)
        #expect(!state.generatedDigest!.content.isEmpty)
        #expect(state.generatedDigest!.source == .bookmarks)
        #expect(state.generatedDigest!.articleCount > 0)
    }

    @Test("Generate digest sets generating state")
    func generateDigestSetsGeneratingState() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        var cancellables = Set<AnyCancellable>()
        var generatingStates: [Bool] = []

        sut.statePublisher
            .map(\.isGenerating)
            .sink { isGenerating in
                generatingStates.append(isGenerating)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .generateDigest)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        #expect(generatingStates.contains(true))
        #expect(generatingStates.last == false)
    }

    @Test("Generate digest streams progress")
    func generateDigestStreamsProgress() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        var cancellables = Set<AnyCancellable>()
        var progressUpdates: [String] = []

        sut.statePublisher
            .map(\.generationProgress)
            .sink { progress in
                if !progress.isEmpty {
                    progressUpdates.append(progress)
                }
            }
            .store(in: &cancellables)

        sut.dispatch(action: .generateDigest)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        #expect(!progressUpdates.isEmpty)
    }

    @Test("Generate digest handles generation error")
    func generateDigestHandlesError() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        mockLLMService.generateResult = .failure(LLMError.inferenceTimeout)
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let state = sut.currentState
        #expect(!state.isGenerating)
        if case .generationFailed = state.error {
            // Expected
        } else {
            Issue.record("Expected generationFailed error")
        }
    }

    // MARK: - Cancel Generation Tests

    @Test("Cancel generation stops generation")
    func cancelGenerationStopsGeneration() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        mockLLMService.generateDelay = 2.0 // Long delay to ensure we can cancel
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.isGenerating)

        sut.dispatch(action: .cancelGeneration)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!sut.currentState.isGenerating)
    }

    // MARK: - Clear Digest Tests

    @Test("Clear digest removes generated digest")
    func clearDigestRemovesDigest() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        await loadModelAndWait()

        sut.dispatch(action: .selectSource(.bookmarks))
        try await Task.sleep(nanoseconds: 500_000_000)

        sut.dispatch(action: .generateDigest)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        #expect(sut.currentState.generatedDigest != nil)

        sut.dispatch(action: .clearDigest)

        #expect(sut.currentState.generatedDigest == nil)
    }

    // MARK: - Unload Model Tests

    @Test("Unload model updates status")
    func unloadModelUpdatesStatus() async throws {
        await loadModelAndWait()

        #expect(sut.currentState.modelStatus == .ready)

        sut.dispatch(action: .unloadModel)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.modelStatus == .notLoaded)
    }

    // MARK: - All Sources Tests

    @Test("All digest sources can be selected")
    func allSourcesCanBeSelected() async throws {
        mockStorageService.mockBookmarkedArticles = Article.mockArticles
        mockStorageService.mockReadingHistory = Article.mockArticles
        mockStorageService.mockUserPreferences = UserPreferences(
            followedTopics: [.technology],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        mockDigestService.freshNewsResult = .success(Article.mockArticles)

        for source in DigestSource.allCases {
            sut.dispatch(action: .selectSource(source))
            try await Task.sleep(nanoseconds: 500_000_000)

            let state = sut.currentState
            #expect(state.selectedSource == source)
        }
    }

    // MARK: - Helpers

    private func loadModelAndWait() async {
        sut.dispatch(action: .loadModelIfNeeded)
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}
