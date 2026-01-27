import Foundation
@testable import Pulse
import Testing

@Suite("SearchDomainAction Tests")
struct SearchDomainActionTests {
    @Test("updateQuery action with string")
    func updateQuery() {
        let action = SearchDomainAction.updateQuery("test query")

        if case let .updateQuery(query) = action {
            #expect(query == "test query")
        } else {
            Issue.record("Expected updateQuery action")
        }
    }

    @Test("updateQuery with empty string")
    func updateQueryEmpty() {
        let action = SearchDomainAction.updateQuery("")

        if case let .updateQuery(query) = action {
            #expect(query == "")
        } else {
            Issue.record("Expected updateQuery action")
        }
    }

    @Test("search action exists")
    func search() {
        let action = SearchDomainAction.search
        #expect(action == .search)
    }

    @Test("loadMore action exists")
    func loadMore() {
        let action = SearchDomainAction.loadMore
        #expect(action == .loadMore)
    }

    @Test("clearResults action exists")
    func clearResults() {
        let action = SearchDomainAction.clearResults
        #expect(action == .clearResults)
    }

    @Test("setSortOption with relevancy")
    func setSortOptionRelevancy() {
        let action = SearchDomainAction.setSortOption(.relevancy)

        if case let .setSortOption(option) = action {
            #expect(option == .relevancy)
        } else {
            Issue.record("Expected setSortOption action")
        }
    }

    @Test("setSortOption with publishedAt")
    func setSortOptionPublishedAt() {
        let action = SearchDomainAction.setSortOption(.publishedAt)

        if case let .setSortOption(option) = action {
            #expect(option == .publishedAt)
        } else {
            Issue.record("Expected setSortOption action")
        }
    }

    @Test("setSortOption with popularity")
    func setSortOptionPopularity() {
        let action = SearchDomainAction.setSortOption(.popularity)

        if case let .setSortOption(option) = action {
            #expect(option == .popularity)
        } else {
            Issue.record("Expected setSortOption action")
        }
    }

    @Test("selectArticle with article ID")
    func selectArticle() {
        let action = SearchDomainAction.selectArticle(articleId: "article-123")

        if case let .selectArticle(articleId) = action {
            #expect(articleId == "article-123")
        } else {
            Issue.record("Expected selectArticle action")
        }
    }

    @Test("clearSelectedArticle action exists")
    func clearSelectedArticle() {
        let action = SearchDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(SearchDomainAction.search == SearchDomainAction.search)
        #expect(SearchDomainAction.loadMore == SearchDomainAction.loadMore)
        #expect(SearchDomainAction.clearResults == SearchDomainAction.clearResults)
        #expect(SearchDomainAction.clearSelectedArticle == SearchDomainAction.clearSelectedArticle)
        #expect(SearchDomainAction.updateQuery("test") == SearchDomainAction.updateQuery("test"))
        #expect(SearchDomainAction.setSortOption(.relevancy) == SearchDomainAction.setSortOption(.relevancy))
        #expect(SearchDomainAction.selectArticle(articleId: "id") == SearchDomainAction.selectArticle(articleId: "id"))
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(SearchDomainAction.search != SearchDomainAction.loadMore)
        #expect(SearchDomainAction.updateQuery("a") != SearchDomainAction.updateQuery("b"))
        #expect(SearchDomainAction.setSortOption(.relevancy) != SearchDomainAction.setSortOption(.popularity))
        #expect(SearchDomainAction.selectArticle(articleId: "1") != SearchDomainAction.selectArticle(articleId: "2"))
    }
}
