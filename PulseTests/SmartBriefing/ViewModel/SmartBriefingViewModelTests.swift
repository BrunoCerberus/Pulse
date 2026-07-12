import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SmartBriefingViewModel Tests", .serialized)
@MainActor
struct SmartBriefingViewModelTests {
    let mockNewsService: MockNewsService
    let mockForYouService: MockForYouService
    let mockPlaybackQueueService: MockPlaybackQueueService
    let mockStoreKitService: MockStoreKitService
    let serviceLocator: ServiceLocator

    init() {
        mockNewsService = MockNewsService()
        mockForYouService = MockForYouService()
        mockPlaybackQueueService = MockPlaybackQueueService()
        mockStoreKitService = MockStoreKitService(isPremium: true)
        serviceLocator = ServiceLocator()

        serviceLocator.register(NewsService.self, instance: mockNewsService)
        serviceLocator.register(ForYouService.self, instance: mockForYouService)
        serviceLocator.register(PlaybackQueueService.self, instance: mockPlaybackQueueService)
        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)
    }

    @Test("isVisible mirrors the premium entitlement")
    func isVisibleMirrorsPremium() async {
        let sut = SmartBriefingViewModel(serviceLocator: serviceLocator)

        let success = await waitForCondition(timeout: 1_000_000_000) { @MainActor in
            sut.viewState.isVisible
        }
        #expect(success)
    }

    @Test("A terminal status message auto-dismisses back to nil after the configured delay")
    func statusMessageAutoDismisses() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockForYouService.scoredArticlesResult = .success(
            Article.mockArticles.map { ScoredArticle(article: $0, score: 1.0, matchedTopics: []) }
        )
        let sut = SmartBriefingViewModel(serviceLocator: serviceLocator, statusDismissalDelay: .milliseconds(50))

        sut.handle(event: .onBuildBriefingTapped)

        let messageAppeared = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            sut.viewState.statusMessage != nil
        }
        #expect(messageAppeared, "Status message should appear after a successful build")

        let messageCleared = await waitForCondition(timeout: 1_000_000_000) { @MainActor in
            sut.viewState.statusMessage == nil
        }
        #expect(messageCleared, "Status message should auto-dismiss after the configured delay")
    }

    @Test("onStartFreshTapped reaches the interactor and builds a queue")
    func onStartFreshTappedBuildsQueue() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockForYouService.scoredArticlesResult = .success(
            Article.mockArticles.map { ScoredArticle(article: $0, score: 1.0, matchedTopics: []) }
        )
        let sut = SmartBriefingViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onStartFreshTapped)

        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor [mockPlaybackQueueService] in
            mockPlaybackQueueService.playCallCount > 0
        }
        #expect(success, "onStartFreshTapped should dispatch .startBriefing(scope: .allUnread) through to playback")
    }

    @Test("An empty build result surfaces the localized empty-state status message")
    func emptyResultSurfacesEmptyMessage() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        mockForYouService.scoredArticlesResult = .success([])
        let sut = SmartBriefingViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onBuildBriefingTapped)

        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            sut.viewState.statusMessage != nil
        }
        #expect(success)
        #expect(sut.viewState.statusMessage == AppLocalization.localized("smart_briefing.empty_message"))
    }

    @Test("A scoring error surfaces its message as the status message")
    func errorResultSurfacesErrorMessage() async {
        mockNewsService.topHeadlinesResult = .success(Article.mockArticles)
        struct ScoringError: Error, LocalizedError {
            var errorDescription: String? {
                "Scoring blew up"
            }
        }
        mockForYouService.scoredArticlesResult = .failure(ScoringError())
        let sut = SmartBriefingViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onBuildBriefingTapped)

        let success = await waitForCondition(timeout: 2_000_000_000) { @MainActor in
            sut.viewState.statusMessage != nil
        }
        #expect(success)
        #expect(sut.viewState.statusMessage == "Scoring blew up")
    }
}
