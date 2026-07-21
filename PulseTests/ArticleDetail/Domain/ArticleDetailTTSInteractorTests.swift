import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainInteractor TTS Tests")
@MainActor
struct ArticleDetailTTSInteractorTests {
    let mockStorageService: MockStorageService
    let mockPlaybackQueueService: MockPlaybackQueueService
    let serviceLocator: ServiceLocator
    let testArticle: Article

    init() {
        mockStorageService = MockStorageService()
        mockPlaybackQueueService = MockPlaybackQueueService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        testArticle = Article.mockArticles[0]
    }

    private func createSUT(article: Article? = nil) -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(
            article: article ?? testArticle,
            serviceLocator: serviceLocator,
        )
    }

    @Test("listen plays a single-item queue for the article")
    func listenPlaysSingleItem() {
        let sut = createSUT()

        sut.dispatch(action: .listen)

        #expect(mockPlaybackQueueService.playCallCount == 1)
        #expect(mockPlaybackQueueService.lastPlayedMode == .singleArticle)
        #expect(mockPlaybackQueueService.lastPlayedItems?.count == 1)

        let item = mockPlaybackQueueService.lastPlayedItems?.first
        #expect(item?.id == testArticle.id)
        #expect(item?.title == testArticle.title)
        #expect(item?.sourceName == testArticle.source.name)
        #expect(item?.speechText.contains(testArticle.title) == true)
        if case let .article(stored) = item?.kind {
            #expect(stored.id == testArticle.id)
        } else {
            Issue.record("Expected .article kind")
        }
    }

    @Test("listen replaces the queue on repeated taps")
    func listenReplacesOnRepeat() {
        let sut = createSUT()

        sut.dispatch(action: .listen)
        sut.dispatch(action: .listen)

        #expect(mockPlaybackQueueService.playCallCount == 2)
        #expect(mockPlaybackQueueService.lastPlayedItems?.count == 1)
    }

    @Test("listen item snapshots the current app language")
    func listenCapturesLanguage() {
        let sut = createSUT()

        sut.dispatch(action: .listen)

        let language = mockPlaybackQueueService.lastPlayedItems?.first?.language
        #expect(language == AppLocalization.shared.language)
    }

    @Test("listen without a registered queue service is a no-op")
    func listenWithoutServiceNoOp() {
        let bareLocator = ServiceLocator()
        bareLocator.register(StorageService.self, instance: mockStorageService)
        let sut = ArticleDetailDomainInteractor(article: testArticle, serviceLocator: bareLocator)

        sut.dispatch(action: .listen)

        #expect(mockPlaybackQueueService.playCallCount == 0)
    }

    @Test("deinit does not stop global playback")
    func deinitLeavesPlaybackRunning() async throws {
        var sut: ArticleDetailDomainInteractor? = createSUT()
        sut?.dispatch(action: .listen)
        #expect(mockPlaybackQueueService.playCallCount == 1)

        sut = nil
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(mockPlaybackQueueService.stopCallCount == 0)
        #expect(mockPlaybackQueueService.currentState.currentIndex == 0)
    }
}
