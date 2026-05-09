import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouViewModel Tests")
@MainActor
struct ForYouViewModelTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    let serviceLocator: ServiceLocator
    let mockForYou: MockForYouService
    let mockRemoteConfig: MockRemoteConfigService

    init() {
        serviceLocator = ServiceLocator()
        mockForYou = MockForYouService()
        mockRemoteConfig = MockRemoteConfigService()
        serviceLocator.register(ForYouService.self, instance: mockForYou)
        serviceLocator.register(RemoteConfigService.self, instance: mockRemoteConfig)
        serviceLocator.register(InterestProfileService.self, instance: MockInterestProfileService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
    }

    private func makeArticle(id: String) -> Article {
        Article(
            id: id,
            title: "Article \(id)",
            description: nil,
            content: nil,
            author: nil,
            source: ArticleSource(id: "src", name: "Source"),
            url: "https://example.com/\(id)",
            imageURL: nil,
            publishedAt: Self.baseDate,
            category: .technology
        )
    }

    private func makeScoredArticle(id: String, score: Double) -> ScoredArticle {
        ScoredArticle(article: makeArticle(id: id), score: score, matchedTopics: ["technology"])
    }

    private func waitForMainActorCondition(_ predicate: @MainActor @escaping () -> Bool) async -> Bool {
        await waitForCondition(timeout: TestWaitDuration.long, condition: predicate)
    }

    @Test("Initial viewState is hidden with no cards")
    func initialState() {
        let sut = ForYouViewModel(serviceLocator: serviceLocator)
        #expect(sut.viewState.isVisible == false)
        #expect(sut.viewState.cards.isEmpty)
    }

    @Test("After scoring, viewState becomes visible with mapped cards")
    func scoringMapsCards() async {
        mockRemoteConfig.forYouEnabledValue = true
        mockForYou.scoredArticlesResult = .success([
            makeScoredArticle(id: "a", score: 0.9),
            makeScoredArticle(id: "b", score: 0.5),
        ])
        let sut = ForYouViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onPoolChanged([makeArticle(id: "a"), makeArticle(id: "b")]))

        let visible = await waitForMainActorCondition { [sut] in
            sut.viewState.isVisible && sut.viewState.cards.count == 2
        }
        #expect(visible)
        #expect(sut.viewState.cards[0].id == "a")
        #expect(sut.viewState.cards[1].id == "b")
        #expect(sut.viewState.cards[0].animationIndex == 0)
        #expect(sut.viewState.cards[1].animationIndex == 1)
    }

    @Test("Cards include explanation strings derived from matched topics")
    func cardsIncludeExplanation() async {
        mockRemoteConfig.forYouEnabledValue = true
        mockForYou.scoredArticlesResult = .success([makeScoredArticle(id: "a", score: 0.9)])
        mockForYou.explanationOverride = "Tech, Science"
        let sut = ForYouViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onPoolChanged([makeArticle(id: "a")]))

        let populated = await waitForMainActorCondition { [sut] in
            !sut.viewState.cards.isEmpty
        }
        #expect(populated)
        #expect(sut.viewState.cards.first?.explanation == "Tech, Science")
    }

    @Test("With feature flag off, the carousel stays hidden even with results")
    func featureFlagOffHidesCarousel() async throws {
        mockRemoteConfig.forYouEnabledValue = false
        mockForYou.scoredArticlesResult = .success([makeScoredArticle(id: "a", score: 0.9)])
        let sut = ForYouViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onPoolChanged([makeArticle(id: "a")]))
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.isVisible == false)
        #expect(sut.viewState.cards.isEmpty)
    }

    @Test("onFeatureFlagChanged event toggles visibility live")
    func featureFlagChangedAtRuntime() async throws {
        mockRemoteConfig.forYouEnabledValue = false
        mockForYou.scoredArticlesResult = .success([makeScoredArticle(id: "a", score: 0.9)])
        let sut = ForYouViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onPoolChanged([makeArticle(id: "a")]))
        try await waitForStateUpdate(duration: TestWaitDuration.long)
        #expect(sut.viewState.isVisible == false)

        // Flip the flag at runtime.
        sut.handle(event: .onFeatureFlagChanged(true))
        // Pool needs a re-score to refill (current implementation clears
        // when flag goes off). Re-dispatching the pool re-scores.
        sut.handle(event: .onPoolChanged([makeArticle(id: "a")]))

        let nowVisible = await waitForMainActorCondition { [sut] in
            sut.viewState.isVisible
        }
        #expect(nowVisible)
    }
}
