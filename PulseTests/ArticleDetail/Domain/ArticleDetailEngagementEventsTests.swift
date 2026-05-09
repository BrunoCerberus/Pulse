import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainInteractor Engagement Events")
@MainActor
struct ArticleDetailEngagementEventsTests {
    let mockStorageService: MockStorageService
    let mockEngagementService: MockEngagementEventsService
    let mockRemoteConfig: MockRemoteConfigService
    let serviceLocator: ServiceLocator
    let testArticle: Article

    init() {
        mockStorageService = MockStorageService()
        mockEngagementService = MockEngagementEventsService()
        mockRemoteConfig = MockRemoteConfigService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: mockStorageService)
        serviceLocator.register(EngagementEventsService.self, instance: mockEngagementService)
        serviceLocator.register(RemoteConfigService.self, instance: mockRemoteConfig)
        testArticle = Article.mockArticles[0]
    }

    private func createSUT(article: Article? = nil) -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(
            article: article ?? testArticle,
            serviceLocator: serviceLocator
        )
    }

    private func waitForEngagement(_ predicate: @MainActor @escaping () -> Bool) async -> Bool {
        await waitForCondition(timeout: TestWaitDuration.long, condition: predicate)
    }

    // MARK: - Flag-on, signals captured

    @Test("Bookmarking captures a .bookmarked engagement event when flag is enabled")
    func bookmarkingCapturesEvent() async {
        mockRemoteConfig.forYouEnabledValue = true
        let sut = createSUT()

        sut.dispatch(action: .toggleBookmark)
        let captured = await waitForEngagement { [mockEngagementService] in
            mockEngagementService.recordedEvents.contains(where: { $0.kind == .bookmarked })
        }

        #expect(captured)
        let event = mockEngagementService.recordedEvents.first(where: { $0.kind == .bookmarked })
        #expect(event?.articleID == testArticle.id)
        #expect(event?.weight == 3.0)
    }

    @Test("Unbookmarking does not capture an engagement event")
    func unbookmarkingDoesNotCapture() async throws {
        mockRemoteConfig.forYouEnabledValue = true
        mockStorageService.bookmarkedArticles = [testArticle]
        let sut = createSUT()
        sut.dispatch(action: .bookmarkStatusLoaded(true))

        sut.dispatch(action: .toggleBookmark)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockEngagementService.recordedEvents.isEmpty)
    }

    @Test("Sharing captures a .shared engagement event when flag is enabled")
    func sharingCapturesEvent() async {
        mockRemoteConfig.forYouEnabledValue = true
        let sut = createSUT()

        sut.dispatch(action: .showShareSheet)
        let captured = await waitForEngagement { [mockEngagementService] in
            mockEngagementService.recordedEvents.contains(where: { $0.kind == .shared })
        }

        #expect(captured)
        let event = mockEngagementService.recordedEvents.first(where: { $0.kind == .shared })
        #expect(event?.weight == 4.0)
    }

    // MARK: - Flag-off, signals suppressed

    @Test("Bookmarking does not capture when the for_you flag is off")
    func bookmarkingSuppressedWhenFlagOff() async throws {
        mockRemoteConfig.forYouEnabledValue = false
        let sut = createSUT()

        sut.dispatch(action: .toggleBookmark)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockEngagementService.recordedEvents.isEmpty)
    }

    @Test("Sharing does not capture when the for_you flag is off")
    func sharingSuppressedWhenFlagOff() async throws {
        mockRemoteConfig.forYouEnabledValue = false
        let sut = createSUT()

        sut.dispatch(action: .showShareSheet)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(mockEngagementService.recordedEvents.isEmpty)
    }

    // MARK: - Captured payload integrity

    @Test("Captured event snapshots the article fields at event time")
    func capturedEventSnapshotsArticleFields() async throws {
        mockRemoteConfig.forYouEnabledValue = true
        let sut = createSUT()

        sut.dispatch(action: .showShareSheet)
        _ = await waitForEngagement { [mockEngagementService] in
            !mockEngagementService.recordedEvents.isEmpty
        }

        let event = try #require(mockEngagementService.recordedEvents.first)
        #expect(event.articleID == testArticle.id)
        #expect(event.articleTitle == testArticle.title)
        #expect(event.categoryRaw == testArticle.category?.rawValue)
    }
}
