import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouDomainInteractor Tests")
@MainActor
struct ForYouDomainInteractorTests {
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    let serviceLocator: ServiceLocator
    let mockForYou: MockForYouService
    let mockProfile: MockInterestProfileService

    init() {
        serviceLocator = ServiceLocator()
        mockForYou = MockForYouService()
        mockProfile = MockInterestProfileService()

        serviceLocator.register(ForYouService.self, instance: mockForYou)
        serviceLocator.register(InterestProfileService.self, instance: mockProfile)
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

    /// Force the `@MainActor` overload of `waitForCondition` by annotating
    /// the predicate. Without this, Swift 6 picks the `sending` overload
    /// and rejects MainActor-isolated reads in the closure body.
    private func waitForMainActorCondition(_ predicate: @MainActor @escaping () -> Bool) async -> Bool {
        await waitForCondition(timeout: TestWaitDuration.long, condition: predicate)
    }

    // MARK: - Initial State

    @Test("Initial state has empty articles and not loading")
    func initialState() {
        let sut = ForYouDomainInteractor(serviceLocator: serviceLocator)
        #expect(sut.currentState.scoredArticles.isEmpty)
        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.error == nil)
    }

    // MARK: - Scoring flow

    @Test("scoreFromPool fetches scored articles and updates state")
    func scoreFromPoolUpdatesState() async {
        mockForYou.scoredArticlesResult = .success([
            makeScoredArticle(id: "a", score: 0.9),
            makeScoredArticle(id: "b", score: 0.5),
        ])
        let sut = ForYouDomainInteractor(serviceLocator: serviceLocator)

        sut.dispatch(action: .scoreFromPool(pool: [makeArticle(id: "a"), makeArticle(id: "b")]))

        let updated = await waitForMainActorCondition { [sut] in
            !sut.currentState.scoredArticles.isEmpty
        }
        #expect(updated)
        #expect(sut.currentState.scoredArticles.count == 2)
        #expect(sut.currentState.isLoading == false)
    }

    @Test("Empty pool clears the scored-articles state")
    func emptyPoolClearsState() async throws {
        let sut = ForYouDomainInteractor(serviceLocator: serviceLocator)
        // First populate
        mockForYou.scoredArticlesResult = .success([makeScoredArticle(id: "a", score: 0.9)])
        sut.dispatch(action: .scoreFromPool(pool: [makeArticle(id: "a")]))
        _ = await waitForMainActorCondition { [sut] in
            !sut.currentState.scoredArticles.isEmpty
        }
        // Then clear
        sut.dispatch(action: .scoreFromPool(pool: []))
        try await waitForStateUpdate(duration: TestWaitDuration.short)

        #expect(sut.currentState.scoredArticles.isEmpty)
    }

    @Test("Scoring errors clear the carousel and surface error message")
    func scoringErrorClearsCarousel() async {
        struct Boom: Error, LocalizedError {
            var errorDescription: String? {
                "boom"
            }
        }
        mockForYou.scoredArticlesResult = .failure(Boom())
        let sut = ForYouDomainInteractor(serviceLocator: serviceLocator)

        sut.dispatch(action: .scoreFromPool(pool: [makeArticle(id: "a")]))
        let errored = await waitForMainActorCondition { [sut] in
            sut.currentState.error != nil
        }
        #expect(errored)
        #expect(sut.currentState.scoredArticles.isEmpty)
        #expect(sut.currentState.isLoading == false)
    }

    // MARK: - Reactivity

    @Test("Receives interestProfileDidChange and re-scores against the last pool")
    func reactsToProfileChange() async {
        let sut = ForYouDomainInteractor(serviceLocator: serviceLocator)
        // Seed an initial pool.
        mockForYou.scoredArticlesResult = .success([makeScoredArticle(id: "a", score: 0.5)])
        sut.dispatch(action: .scoreFromPool(pool: [makeArticle(id: "a")]))
        _ = await waitForMainActorCondition { [sut] in
            !sut.currentState.scoredArticles.isEmpty
        }
        // Swap the result and post the notification.
        mockForYou.scoredArticlesResult = .success([
            makeScoredArticle(id: "a", score: 0.9),
            makeScoredArticle(id: "b", score: 0.7),
        ])
        NotificationCenter.default.post(name: .interestProfileDidChange, object: nil)

        let rescored = await waitForMainActorCondition { [sut] in
            sut.currentState.scoredArticles.count == 2
        }
        #expect(rescored)
    }
}
