import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryDomainState Tests")
struct ReadingHistoryDomainStateTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testArticles: [Article] {
        [
            Article(
                id: "article-1",
                title: "Article 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://example.com/1",
                publishedAt: Self.referenceDate
            ),
            Article(
                id: "article-2",
                title: "Article 2",
                source: ArticleSource(id: "source-2", name: "Source 2"),
                url: "https://example.com/2",
                publishedAt: Self.referenceDate.addingTimeInterval(-3600)
            ),
        ]
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct default values")
    func initialState() {
        let state = ReadingHistoryDomainState.initial

        #expect(state.articles.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.error == nil)
        #expect(state.selectedArticle == nil)
    }

    // MARK: - State Properties Tests

    @Test("Articles can be set")
    func articlesCanBeSet() {
        var state = ReadingHistoryDomainState.initial
        state.articles = testArticles

        #expect(state.articles.count == 2)
        #expect(state.articles[0].id == "article-1")
        #expect(state.articles[1].id == "article-2")
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = ReadingHistoryDomainState.initial
        #expect(state.isLoading == false)

        state.isLoading = true
        #expect(state.isLoading == true)
    }

    @Test("Error can be set")
    func errorCanBeSet() {
        var state = ReadingHistoryDomainState.initial
        #expect(state.error == nil)

        state.error = "Storage error"
        #expect(state.error == "Storage error")
    }

    @Test("Selected article can be set")
    func selectedArticleCanBeSet() {
        var state = ReadingHistoryDomainState.initial
        #expect(state.selectedArticle == nil)

        state.selectedArticle = testArticles[0]
        #expect(state.selectedArticle?.id == "article-1")
    }

    @Test("Selected article can be cleared")
    func selectedArticleCanBeCleared() {
        var state = ReadingHistoryDomainState.initial
        state.selectedArticle = testArticles[0]
        #expect(state.selectedArticle != nil)

        state.selectedArticle = nil
        #expect(state.selectedArticle == nil)
    }

    // MARK: - Equatable Tests

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = ReadingHistoryDomainState.initial
        let state2 = ReadingHistoryDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different articles are not equal")
    func statesWithDifferentArticles() {
        let state1 = ReadingHistoryDomainState.initial
        var state2 = ReadingHistoryDomainState.initial
        state2.articles = testArticles

        #expect(state1 != state2)
    }

    @Test("States with different isLoading are not equal")
    func statesWithDifferentIsLoading() {
        let state1 = ReadingHistoryDomainState.initial
        var state2 = ReadingHistoryDomainState.initial
        state2.isLoading = true

        #expect(state1 != state2)
    }

    @Test("States with different errors are not equal")
    func statesWithDifferentErrors() {
        let state1 = ReadingHistoryDomainState.initial
        var state2 = ReadingHistoryDomainState.initial
        state2.error = "Error message"

        #expect(state1 != state2)
    }

    @Test("States with different selected articles are not equal")
    func statesWithDifferentSelectedArticles() {
        let state1 = ReadingHistoryDomainState.initial
        var state2 = ReadingHistoryDomainState.initial
        state2.selectedArticle = testArticles[0]

        #expect(state1 != state2)
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = ReadingHistoryDomainState.initial
        state1.articles = testArticles
        state1.isLoading = true
        state1.error = "Test error"

        var state2 = ReadingHistoryDomainState.initial
        state2.articles = testArticles
        state2.isLoading = true
        state2.error = "Test error"

        #expect(state1 == state2)
    }
}
