import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryDomainInteractor Extended Tests")
@MainActor
// swiftlint:disable:next type_name
struct ReadingHistoryDomainInteractorExtendedTests {
    let mockStorageService: MockStorageService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator

    init() {
        mockStorageService = MockStorageService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)
    }

    private func createSUT() -> ReadingHistoryDomainInteractor {
        ReadingHistoryDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Share Article Tests

    @Test("Share article updates articleToShare state")
    func shareArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))

        #expect(sut.currentState.articleToShare?.id == articles[0].id)
    }

    @Test("Share non-existent article does not set state")
    func shareNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: "non-existent"))

        #expect(sut.currentState.articleToShare == nil)
    }

    @Test("Clear article to share resets state")
    func clearArticleToShare() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))
        #expect(sut.currentState.articleToShare != nil)

        sut.dispatch(action: .clearArticleToShare)
        #expect(sut.currentState.articleToShare == nil)
    }

    // MARK: - Bookmark Article Tests

    @Test("Bookmark article saves when not bookmarked")
    func bookmarkArticleSaves() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockStorageService.bookmarkedArticles.contains(where: { $0.id == articles[0].id }))
    }

    @Test("Bookmark article removes when already bookmarked")
    func bookmarkArticleRemoves() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles
        mockStorageService.bookmarkedArticles = [articles[0]]

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!mockStorageService.bookmarkedArticles.contains(where: { $0.id == articles[0].id }))
    }

    @Test("Bookmark non-existent article does nothing")
    func bookmarkNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let initialCount = mockStorageService.bookmarkedArticles.count
        sut.dispatch(action: .bookmarkArticle(articleId: "non-existent"))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockStorageService.bookmarkedArticles.count == initialCount)
    }

    // MARK: - Select Non-existent Article Tests

    @Test("Select non-existent article does not set selection")
    func selectNonExistentArticle() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .selectArticle(articleId: "non-existent"))
        #expect(sut.currentState.selectedArticle == nil)
    }

    // MARK: - Clear History Notification Tests

    @Test("Clear history posts notification")
    func clearHistoryPostsNotification() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .readingHistoryDidClear,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        sut.dispatch(action: .clearHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(notificationReceived)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Analytics Tests

    @Test("Share article logs analytics event")
    func shareArticleLogsEvent() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .shareArticle(articleId: articles[0].id))

        let shareEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_shared" }
        #expect(shareEvents.count == 1)
    }

    @Test("Bookmark article logs bookmarked event")
    func bookmarkArticleLogsEvent() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let bookmarkEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_bookmarked" }
        #expect(bookmarkEvents.count == 1)
    }

    @Test("Unbookmark article logs unbookmarked event")
    func unbookmarkArticleLogsEvent() async throws {
        let articles = Article.mockArticles
        mockStorageService.readArticles = articles
        mockStorageService.bookmarkedArticles = [articles[0]]

        let sut = createSUT()
        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        sut.dispatch(action: .bookmarkArticle(articleId: articles[0].id))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let unbookmarkEvents = mockAnalyticsService.loggedEvents.filter { $0.name == "article_unbookmarked" }
        #expect(unbookmarkEvents.count == 1)
    }

    // MARK: - State Publisher Tests

    @Test("State publisher emits loading transitions")
    func statePublisherLoadingTransitions() async throws {
        mockStorageService.readArticles = Article.mockArticles

        let sut = createSUT()
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoading)
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        sut.dispatch(action: .loadHistory)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
    }
}
