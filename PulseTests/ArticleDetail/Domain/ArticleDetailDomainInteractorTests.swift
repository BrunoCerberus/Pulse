import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainInteractor Tests")
@MainActor
struct ArticleDetailDomainInteractorTests {
    let mockStorageService: MockStorageService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let testArticle: Article

    init() {
        mockStorageService = MockStorageService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
        testArticle = Article.mockArticles[0]
    }

    private func createSUT(article: Article? = nil) -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(
            article: article ?? testArticle,
            serviceLocator: serviceLocator
        )
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct values")
    func initialState() {
        let sut = createSUT()
        let state = sut.currentState

        #expect(state.article.id == testArticle.id)
        #expect(state.isProcessingContent == true)
        #expect(state.processedContent == nil)
        #expect(state.processedDescription == nil)
        #expect(state.isBookmarked == false)
        #expect(state.showShareSheet == false)
        #expect(state.showSummarizationSheet == false)
        #expect(state.ttsPlaybackState == .idle)
        #expect(state.ttsProgress == 0.0)
        #expect(state.ttsSpeedPreset == .normal)
        #expect(state.isTTSPlayerVisible == false)
    }

    // MARK: - onAppear Tests

    @Test("onAppear checks bookmark status")
    func onAppearChecksBookmarkStatus() async throws {
        mockStorageService.bookmarkedArticles = [testArticle]
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isBookmarked == true)
    }

    @Test("onAppear marks article as read")
    func onAppearMarksAsRead() async throws {
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let isRead = await mockStorageService.isRead(testArticle.id)
        #expect(isRead == true)
    }

    @Test("onAppear sets isBookmarked to false when not bookmarked")
    func onAppearNotBookmarked() async throws {
        mockStorageService.bookmarkedArticles = []
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isBookmarked == false)
    }

    // MARK: - Bookmark Toggle Tests

    @Test("toggleBookmark adds bookmark when not bookmarked")
    func toggleBookmarkAdds() async throws {
        let sut = createSUT()

        sut.dispatch(action: .toggleBookmark)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isBookmarked == true)
        let isBookmarked = await mockStorageService.isBookmarked(testArticle.id)
        #expect(isBookmarked == true)
    }

    @Test("toggleBookmark removes bookmark when already bookmarked")
    func toggleBookmarkRemoves() async throws {
        mockStorageService.bookmarkedArticles = [testArticle]
        let sut = createSUT()

        // Set initial bookmark state
        sut.dispatch(action: .bookmarkStatusLoaded(true))

        sut.dispatch(action: .toggleBookmark)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isBookmarked == false)
    }

    @Test("toggleBookmark performs optimistic update")
    func toggleBookmarkOptimistic() async throws {
        let sut = createSUT()

        // Capture state immediately after dispatch
        var states: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        sut.statePublisher
            .map(\.isBookmarked)
            .sink { states.append($0) }
            .store(in: &cancellables)

        sut.dispatch(action: .toggleBookmark)

        // Allow pipeline to propagate
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        // Should have optimistically updated to true
        #expect(states.contains(true))
    }

    // MARK: - Share Sheet Tests

    @Test("showShareSheet updates state")
    func showShareSheet() {
        let sut = createSUT()

        sut.dispatch(action: .showShareSheet)

        #expect(sut.currentState.showShareSheet == true)
    }

    @Test("dismissShareSheet updates state")
    func dismissShareSheet() {
        let sut = createSUT()

        sut.dispatch(action: .showShareSheet)
        sut.dispatch(action: .dismissShareSheet)

        #expect(sut.currentState.showShareSheet == false)
    }

    // MARK: - Summarization Sheet Tests

    @Test("showSummarizationSheet updates state")
    func showSummarizationSheet() {
        let sut = createSUT()

        sut.dispatch(action: .showSummarizationSheet)

        #expect(sut.currentState.showSummarizationSheet == true)
    }

    @Test("dismissSummarizationSheet updates state")
    func dismissSummarizationSheet() {
        let sut = createSUT()

        sut.dispatch(action: .showSummarizationSheet)
        sut.dispatch(action: .dismissSummarizationSheet)

        #expect(sut.currentState.showSummarizationSheet == false)
    }

    // MARK: - Content Processing Tests

    @Test("Content processing completes with processed content")
    func contentProcessingCompletes() async {
        let articleWithContent = Article(
            id: "test-1",
            title: "Test Article",
            description: "First sentence. Second sentence. Third sentence.",
            content: "<p>Paragraph one. Sentence two. Sentence three.</p>",
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithContent)

        // Wait for content processing to complete
        let success = await waitForCondition(timeout: 2_000_000_000) {
            !sut.currentState.isProcessingContent &&
                sut.currentState.processedContent != nil &&
                sut.currentState.processedDescription != nil
        }
        #expect(success)
    }

    @Test("Content processing handles nil content")
    func contentProcessingHandlesNil() async {
        let articleWithoutContent = Article(
            id: "test-2",
            title: "Test Article",
            description: nil,
            content: nil,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )
        let sut = createSUT(article: articleWithoutContent)

        // Wait for content processing to complete (should finish quickly with nil values)
        let success = await waitForCondition(timeout: 2_000_000_000) {
            !sut.currentState.isProcessingContent
        }
        #expect(success)
        #expect(sut.currentState.processedContent == nil)
        #expect(sut.currentState.processedDescription == nil)
    }

    @Test("bookmarkStatusLoaded action updates state")
    func bookmarkStatusLoaded() {
        let sut = createSUT()

        sut.dispatch(action: .bookmarkStatusLoaded(true))

        #expect(sut.currentState.isBookmarked == true)

        sut.dispatch(action: .bookmarkStatusLoaded(false))

        #expect(sut.currentState.isBookmarked == false)
    }

    @Test("contentProcessingCompleted action updates state")
    func contentProcessingCompletedAction() {
        let sut = createSUT()

        let testContent = AttributedString("Test content")
        let testDescription = AttributedString("Test description")

        sut.dispatch(action: .contentProcessingCompleted(
            content: testContent,
            description: testDescription
        ))

        #expect(sut.currentState.isProcessingContent == false)
        #expect(sut.currentState.processedContent != nil)
        #expect(sut.currentState.processedDescription != nil)
    }
}

// MARK: - Text Processing Tests

@Suite("ArticleDetailDomainInteractor Text Processing Tests")
struct ArticleDetailTextProcessingTests {
    // Test the text processing utilities by testing behavior through actions

    @Test("HTML tags are stripped from content")
    @MainActor
    func htmlStripping() async throws {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())

        let articleWithHTML = Article(
            id: "html-test",
            title: "Test",
            description: "<p>Description with <strong>bold</strong> text.</p>",
            content: "<div>Content with <a href='test'>link</a> here.</div>",
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )

        let sut = ArticleDetailDomainInteractor(
            article: articleWithHTML,
            serviceLocator: serviceLocator
        )

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        // Verify HTML was stripped (content should not contain < or >)
        if let content = sut.currentState.processedContent {
            let contentString = String(content.characters)
            #expect(!contentString.contains("<"))
            #expect(!contentString.contains(">"))
        }
    }

    @Test("Truncation markers are removed from content")
    @MainActor
    func truncationMarkerRemoval() async throws {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())

        let articleWithTruncation = Article(
            id: "truncation-test",
            title: "Test",
            description: "Short description.",
            content: "This is the content of the article. [+500 chars]",
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )

        let sut = ArticleDetailDomainInteractor(
            article: articleWithTruncation,
            serviceLocator: serviceLocator
        )

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        if let content = sut.currentState.processedContent {
            let contentString = String(content.characters)
            #expect(!contentString.contains("[+"))
            #expect(!contentString.contains("chars]"))
        }
    }

    @Test("HTML entities are decoded")
    @MainActor
    func htmlEntityDecoding() async throws {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())

        let articleWithEntities = Article(
            id: "entity-test",
            title: "Test",
            description: "Text with &amp; and &quot;quotes&quot; here.",
            content: nil,
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            imageURL: nil,
            publishedAt: Date(),
            category: .world
        )

        let sut = ArticleDetailDomainInteractor(
            article: articleWithEntities,
            serviceLocator: serviceLocator
        )

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        if let description = sut.currentState.processedDescription {
            let descString = String(description.characters)
            #expect(descString.contains("&"))
            #expect(descString.contains("\""))
            #expect(!descString.contains("&amp;"))
            #expect(!descString.contains("&quot;"))
        }
    }
}

// MARK: - Analytics Tests

extension ArticleDetailDomainInteractorTests {
    @Test("Logs screen_view on onAppear")
    func logsScreenViewOnAppear() async throws {
        let sut = createSUT()
        sut.dispatch(action: .onAppear)
        try await Task.sleep(nanoseconds: 300_000_000)

        let screenEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "screen_view" }
        #expect(screenEvents.count == 1)
        #expect(screenEvents.first?.parameters?["screen_name"] as? String == "article_detail")
    }

    @Test("Logs article_shared on showShareSheet")
    func logsArticleSharedOnShare() {
        let sut = createSUT()
        sut.dispatch(action: .showShareSheet)

        let sharedEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_shared" }
        #expect(sharedEvents.count == 1)
    }

    @Test("Logs bookmark events on toggleBookmark")
    func logsBookmarkEventsOnToggle() async throws {
        let sut = createSUT()
        sut.dispatch(action: .toggleBookmark)
        try await Task.sleep(nanoseconds: 300_000_000)

        let bookmarkEvents = mockAnalyticsService.loggedEvents.filter {
            $0.name == "article_bookmarked" || $0.name == "article_unbookmarked"
        }
        #expect(bookmarkEvents.count == 1)
    }
}
