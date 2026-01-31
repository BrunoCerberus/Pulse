import Foundation
@testable import Pulse
import Testing

@Suite("FeedDomainAction Tests")
struct FeedDomainActionTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticle: Article {
        Article(
            id: "test-article",
            title: "Test Article",
            source: ArticleSource(id: "test-source", name: "Test Source"),
            url: "https://example.com/article",
            publishedAt: Self.referenceDate,
            category: .technology
        )
    }

    // MARK: - Lifecycle Tests

    @Test("loadInitialData action exists")
    func loadInitialDataAction() {
        let action = FeedDomainAction.loadInitialData
        #expect(action == .loadInitialData)
    }

    // MARK: - Model Management Tests

    @Test("preloadModel action exists")
    func preloadModelAction() {
        let action = FeedDomainAction.preloadModel
        #expect(action == .preloadModel)
    }

    @Test("modelStatusChanged action with notLoaded")
    func modelStatusChangedNotLoaded() {
        let action = FeedDomainAction.modelStatusChanged(.notLoaded)

        if case let .modelStatusChanged(status) = action {
            #expect(status == .notLoaded)
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    @Test("modelStatusChanged action with loading")
    func modelStatusChangedLoading() {
        let action = FeedDomainAction.modelStatusChanged(.loading(progress: 0.5))

        if case let .modelStatusChanged(status) = action {
            #expect(status == .loading(progress: 0.5))
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    @Test("modelStatusChanged action with ready")
    func modelStatusChangedReady() {
        let action = FeedDomainAction.modelStatusChanged(.ready)

        if case let .modelStatusChanged(status) = action {
            #expect(status == .ready)
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    @Test("modelStatusChanged action with error")
    func modelStatusChangedError() {
        let action = FeedDomainAction.modelStatusChanged(.error("Load failed"))

        if case let .modelStatusChanged(status) = action {
            #expect(status == .error("Load failed"))
        } else {
            Issue.record("Expected modelStatusChanged action")
        }
    }

    // MARK: - Articles Tests

    @Test("latestArticlesLoaded action with articles")
    func latestArticlesLoaded() {
        let articles = [testArticle]
        let action = FeedDomainAction.latestArticlesLoaded(articles)

        if case let .latestArticlesLoaded(loadedArticles) = action {
            #expect(loadedArticles.count == 1)
            #expect(loadedArticles[0].id == testArticle.id)
        } else {
            Issue.record("Expected latestArticlesLoaded action")
        }
    }

    @Test("latestArticlesLoaded action with empty array")
    func latestArticlesLoadedEmpty() {
        let action = FeedDomainAction.latestArticlesLoaded([])

        if case let .latestArticlesLoaded(loadedArticles) = action {
            #expect(loadedArticles.isEmpty)
        } else {
            Issue.record("Expected latestArticlesLoaded action")
        }
    }

    @Test("latestArticlesFailed action with error message")
    func latestArticlesFailed() {
        let action = FeedDomainAction.latestArticlesFailed("Failed to load articles")

        if case let .latestArticlesFailed(message) = action {
            #expect(message == "Failed to load articles")
        } else {
            Issue.record("Expected latestArticlesFailed action")
        }
    }

    // MARK: - Digest Generation Tests

    @Test("generateDigest action exists")
    func generateDigestAction() {
        let action = FeedDomainAction.generateDigest
        #expect(action == .generateDigest)
    }

    @Test("digestTokenReceived action with token")
    func digestTokenReceived() {
        let action = FeedDomainAction.digestTokenReceived("Hello world")

        if case let .digestTokenReceived(token) = action {
            #expect(token == "Hello world")
        } else {
            Issue.record("Expected digestTokenReceived action")
        }
    }

    @Test("digestCompleted action with digest")
    func digestCompleted() {
        let digest = DailyDigest(
            id: "digest-1",
            summary: "Test summary",
            sourceArticles: [testArticle],
            generatedAt: Date()
        )
        let action = FeedDomainAction.digestCompleted(digest)

        if case let .digestCompleted(completedDigest) = action {
            #expect(completedDigest.id == "digest-1")
            #expect(completedDigest.summary == "Test summary")
        } else {
            Issue.record("Expected digestCompleted action")
        }
    }

    @Test("digestFailed action with error message")
    func digestFailed() {
        let action = FeedDomainAction.digestFailed("Generation failed")

        if case let .digestFailed(message) = action {
            #expect(message == "Generation failed")
        } else {
            Issue.record("Expected digestFailed action")
        }
    }

    // MARK: - Navigation Tests

    @Test("selectArticle action with article")
    func selectArticle() {
        let action = FeedDomainAction.selectArticle(testArticle)

        if case let .selectArticle(article) = action {
            #expect(article.id == testArticle.id)
        } else {
            Issue.record("Expected selectArticle action")
        }
    }

    @Test("clearSelectedArticle action exists")
    func clearSelectedArticle() {
        let action = FeedDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    // MARK: - State Changes Tests

    @Test("generationStateChanged action with idle")
    func generationStateChangedIdle() {
        let action = FeedDomainAction.generationStateChanged(.idle)

        if case let .generationStateChanged(state) = action {
            #expect(state == .idle)
        } else {
            Issue.record("Expected generationStateChanged action")
        }
    }

    @Test("generationStateChanged action with loadingArticles")
    func generationStateChangedLoadingArticles() {
        let action = FeedDomainAction.generationStateChanged(.loadingArticles)

        if case let .generationStateChanged(state) = action {
            #expect(state == .loadingArticles)
        } else {
            Issue.record("Expected generationStateChanged action")
        }
    }

    @Test("generationStateChanged action with generating")
    func generationStateChangedGenerating() {
        let action = FeedDomainAction.generationStateChanged(.generating)

        if case let .generationStateChanged(state) = action {
            #expect(state == .generating)
        } else {
            Issue.record("Expected generationStateChanged action")
        }
    }

    @Test("generationStateChanged action with completed")
    func generationStateChangedCompleted() {
        let action = FeedDomainAction.generationStateChanged(.completed)

        if case let .generationStateChanged(state) = action {
            #expect(state == .completed)
        } else {
            Issue.record("Expected generationStateChanged action")
        }
    }

    @Test("generationStateChanged action with error")
    func generationStateChangedError() {
        let action = FeedDomainAction.generationStateChanged(.error("Test error"))

        if case let .generationStateChanged(state) = action {
            #expect(state == .error("Test error"))
        } else {
            Issue.record("Expected generationStateChanged action")
        }
    }

    // MARK: - Error Handling Tests

    @Test("clearError action exists")
    func clearErrorAction() {
        let action = FeedDomainAction.clearError
        #expect(action == .clearError)
    }
}

// MARK: - Equatable Tests Extension

extension FeedDomainActionTests {
    @Test("Same simple actions are equal")
    func sameSimpleActionsAreEqual() {
        #expect(FeedDomainAction.loadInitialData == FeedDomainAction.loadInitialData)
        #expect(FeedDomainAction.preloadModel == FeedDomainAction.preloadModel)
        #expect(FeedDomainAction.generateDigest == FeedDomainAction.generateDigest)
        #expect(FeedDomainAction.clearSelectedArticle == FeedDomainAction.clearSelectedArticle)
        #expect(FeedDomainAction.clearError == FeedDomainAction.clearError)
    }

    @Test("Different simple actions are not equal")
    func differentSimpleActionsAreNotEqual() {
        #expect(FeedDomainAction.loadInitialData != FeedDomainAction.preloadModel)
        #expect(FeedDomainAction.generateDigest != FeedDomainAction.clearError)
    }

    @Test("modelStatusChanged with same status are equal")
    func modelStatusChangedSameStatusAreEqual() {
        #expect(
            FeedDomainAction.modelStatusChanged(.ready) ==
                FeedDomainAction.modelStatusChanged(.ready)
        )
    }

    @Test("modelStatusChanged with different status are not equal")
    func modelStatusChangedDifferentStatusAreNotEqual() {
        #expect(
            FeedDomainAction.modelStatusChanged(.ready) !=
                FeedDomainAction.modelStatusChanged(.notLoaded)
        )
    }

    @Test("latestArticlesLoaded with same articles are equal")
    func latestArticlesLoadedSameArticlesAreEqual() {
        #expect(
            FeedDomainAction.latestArticlesLoaded([testArticle]) ==
                FeedDomainAction.latestArticlesLoaded([testArticle])
        )
    }

    @Test("latestArticlesLoaded with different articles are not equal")
    func latestArticlesLoadedDifferentArticlesAreNotEqual() {
        let article2 = Article(
            id: "different-id",
            title: "Different",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )
        #expect(
            FeedDomainAction.latestArticlesLoaded([testArticle]) !=
                FeedDomainAction.latestArticlesLoaded([article2])
        )
    }

    @Test("latestArticlesFailed with same message are equal")
    func latestArticlesFailedSameMessageAreEqual() {
        #expect(
            FeedDomainAction.latestArticlesFailed("Error") ==
                FeedDomainAction.latestArticlesFailed("Error")
        )
    }

    @Test("latestArticlesFailed with different messages are not equal")
    func latestArticlesFailedDifferentMessagesAreNotEqual() {
        #expect(
            FeedDomainAction.latestArticlesFailed("Error 1") !=
                FeedDomainAction.latestArticlesFailed("Error 2")
        )
    }

    @Test("digestTokenReceived with same token are equal")
    func digestTokenReceivedSameTokenAreEqual() {
        #expect(
            FeedDomainAction.digestTokenReceived("token") ==
                FeedDomainAction.digestTokenReceived("token")
        )
    }

    @Test("digestTokenReceived with different tokens are not equal")
    func digestTokenReceivedDifferentTokensAreNotEqual() {
        #expect(
            FeedDomainAction.digestTokenReceived("token1") !=
                FeedDomainAction.digestTokenReceived("token2")
        )
    }

    @Test("digestFailed with same message are equal")
    func digestFailedSameMessageAreEqual() {
        #expect(
            FeedDomainAction.digestFailed("Error") ==
                FeedDomainAction.digestFailed("Error")
        )
    }

    @Test("digestFailed with different messages are not equal")
    func digestFailedDifferentMessagesAreNotEqual() {
        #expect(
            FeedDomainAction.digestFailed("Error 1") !=
                FeedDomainAction.digestFailed("Error 2")
        )
    }

    @Test("generationStateChanged with same state are equal")
    func generationStateChangedSameStateAreEqual() {
        #expect(
            FeedDomainAction.generationStateChanged(.completed) ==
                FeedDomainAction.generationStateChanged(.completed)
        )
    }

    @Test("generationStateChanged with different state are not equal")
    func generationStateChangedDifferentStateAreNotEqual() {
        #expect(
            FeedDomainAction.generationStateChanged(.idle) !=
                FeedDomainAction.generationStateChanged(.generating)
        )
    }

    @Test("selectArticle with same article are equal")
    func selectArticleSameArticleAreEqual() {
        #expect(
            FeedDomainAction.selectArticle(testArticle) ==
                FeedDomainAction.selectArticle(testArticle)
        )
    }
}

// MARK: - Equatable Tests Extension

extension FeedDomainActionTests {
    @Test("selectArticle with different articles are not equal")
    func selectArticleDifferentArticlesAreNotEqual() {
        let article2 = Article(
            id: "different-id",
            title: "Different",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://example.com",
            publishedAt: Date()
        )
        #expect(
            FeedDomainAction.selectArticle(testArticle) !=
                FeedDomainAction.selectArticle(article2)
        )
    }
}
