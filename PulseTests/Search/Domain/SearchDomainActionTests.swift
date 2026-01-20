import Foundation
@testable import Pulse
import Testing

@Suite("SearchDomainAction Query Management Tests")
struct SearchDomainActionQueryManagementTests {
    @Test("Can create updateQuery action with text")
    func updateQueryAction() {
        let query = "Swift programming"
        let action = SearchDomainAction.updateQuery(query)
        #expect(action == .updateQuery(query))
    }

    @Test("Different queries create different actions")
    func differentQueriesDifferentActions() {
        let action1 = SearchDomainAction.updateQuery("Swift")
        let action2 = SearchDomainAction.updateQuery("iOS")
        #expect(action1 != action2)
    }

    @Test("updateQuery with empty string")
    func updateQueryEmpty() {
        let action = SearchDomainAction.updateQuery("")
        #expect(action == .updateQuery(""))
    }

    @Test("updateQuery with special characters")
    func updateQuerySpecialCharacters() {
        let query = "Swift & iOS (18+)"
        let action = SearchDomainAction.updateQuery(query)
        #expect(action == .updateQuery(query))
    }

    @Test("updateQuery with unicode characters")
    func updateQueryUnicode() {
        let query = "新闻 🎉 مرحبا"
        let action = SearchDomainAction.updateQuery(query)
        #expect(action == .updateQuery(query))
    }

    @Test("Can create search action")
    func searchAction() {
        let action1 = SearchDomainAction.search
        let action2 = SearchDomainAction.search
        #expect(action1 == action2)
    }

    @Test("Can create clearResults action")
    func clearResultsAction() {
        let action1 = SearchDomainAction.clearResults
        let action2 = SearchDomainAction.clearResults
        #expect(action1 == action2)
    }
}

@Suite("SearchDomainAction Pagination Tests")
struct SearchDomainActionPaginationTests {
    @Test("Can create loadMore action")
    func loadMoreAction() {
        let action1 = SearchDomainAction.loadMore
        let action2 = SearchDomainAction.loadMore
        #expect(action1 == action2)
    }

    @Test("loadMore is repeatable")
    func loadMoreRepeatable() {
        let actions = Array(repeating: SearchDomainAction.loadMore, count: 5)
        for action in actions {
            #expect(action == .loadMore)
        }
    }
}

@Suite("SearchDomainAction Sort Option Tests")
struct SearchDomainActionSortOptionTests {
    @Test("Can create setSortOption action with relevancy")
    func setSortOptionRelevancy() {
        let action = SearchDomainAction.setSortOption(.relevancy)
        #expect(action == .setSortOption(.relevancy))
    }

    @Test("Can create setSortOption action with publishedAt")
    func setSortOptionPublishedAt() {
        let action = SearchDomainAction.setSortOption(.publishedAt)
        #expect(action == .setSortOption(.publishedAt))
    }

    @Test("Can create setSortOption action with popularity")
    func setSortOptionPopularity() {
        let action = SearchDomainAction.setSortOption(.popularity)
        #expect(action == .setSortOption(.popularity))
    }

    @Test("Different sort options create different actions")
    func differentSortOptionsDifferentActions() {
        let action1 = SearchDomainAction.setSortOption(.relevancy)
        let action2 = SearchDomainAction.setSortOption(.publishedAt)
        let action3 = SearchDomainAction.setSortOption(.popularity)
        #expect(action1 != action2)
        #expect(action2 != action3)
        #expect(action1 != action3)
    }

    @Test("setSortOption with all available options")
    func setSortOptionAllOptions() {
        let options = SearchSortOption.allCases
        let actions = options.map { SearchDomainAction.setSortOption($0) }
        #expect(actions.count == 3)
    }
}

@Suite("SearchDomainAction Article Selection Tests")
struct SearchDomainActionArticleSelectionTests {
    @Test("Can create selectArticle action with ID")
    func selectArticleAction() {
        let id = "article-123"
        let action = SearchDomainAction.selectArticle(articleId: id)
        #expect(action == .selectArticle(articleId: id))
    }

    @Test("Different article IDs create different actions")
    func differentArticleIDsDifferentActions() {
        let action1 = SearchDomainAction.selectArticle(articleId: "article-1")
        let action2 = SearchDomainAction.selectArticle(articleId: "article-2")
        #expect(action1 != action2)
    }

    @Test("selectArticle with empty ID")
    func selectArticleEmptyID() {
        let action = SearchDomainAction.selectArticle(articleId: "")
        #expect(action == .selectArticle(articleId: ""))
    }

    @Test("Can create clearSelectedArticle action")
    func clearSelectedArticleAction() {
        let action1 = SearchDomainAction.clearSelectedArticle
        let action2 = SearchDomainAction.clearSelectedArticle
        #expect(action1 == action2)
    }

    @Test("clearSelectedArticle different from selectArticle")
    func clearDifferentFromSelect() {
        let selectAction = SearchDomainAction.selectArticle(articleId: "article-1")
        let clearAction = SearchDomainAction.clearSelectedArticle
        #expect(selectAction != clearAction)
    }
}

@Suite("SearchDomainAction Equatable Tests")
struct SearchDomainActionEquatableTests {
    @Test("Same simple actions are equal")
    func sameSimpleActionsEqual() {
        let action1 = SearchDomainAction.search
        let action2 = SearchDomainAction.search
        #expect(action1 == action2)
    }

    @Test("Different simple actions not equal")
    func differentSimpleActionsNotEqual() {
        let action1 = SearchDomainAction.search
        let action2 = SearchDomainAction.clearResults
        #expect(action1 != action2)
    }

    @Test("Actions with different associated values not equal")
    func differentAssociatedValuesNotEqual() {
        let action1 = SearchDomainAction.updateQuery("Swift")
        let action2 = SearchDomainAction.updateQuery("iOS")
        #expect(action1 != action2)
    }

    @Test("Actions with same associated values equal")
    func sameAssociatedValuesEqual() {
        let action1 = SearchDomainAction.setSortOption(.relevancy)
        let action2 = SearchDomainAction.setSortOption(.relevancy)
        #expect(action1 == action2)
    }
}

@Suite("SearchDomainAction Complex Search Workflow Tests")
struct SearchDomainActionComplexSearchWorkflowTests {
    @Test("Simulate complete search workflow")
    func completeSearchWorkflow() {
        let actions: [SearchDomainAction] = [
            .updateQuery("Swift"),
            .search,
            .selectArticle(articleId: "article-1"),
            .clearSelectedArticle,
        ]

        #expect(actions.count == 4)
        #expect(actions[0] == .updateQuery("Swift"))
        #expect(actions[1] == .search)
    }

    @Test("Simulate search with pagination")
    func searchWithPagination() {
        let actions: [SearchDomainAction] = [
            .updateQuery("iOS"),
            .search,
            .loadMore,
            .loadMore,
        ]

        #expect(actions.count == 4)
        #expect(actions[2] == .loadMore)
        #expect(actions[3] == .loadMore)
    }

    @Test("Simulate search with sorting")
    func searchWithSorting() {
        let actions: [SearchDomainAction] = [
            .updateQuery("React"),
            .search,
            .setSortOption(.publishedAt),
            .selectArticle(articleId: "article-1"),
        ]

        #expect(actions.count == 4)
        #expect(actions[2] == .setSortOption(.publishedAt))
    }

    @Test("Simulate sort order changes")
    func sortOrderChanges() {
        let actions: [SearchDomainAction] = [
            .search,
            .setSortOption(.relevancy),
            .setSortOption(.publishedAt),
            .setSortOption(.popularity),
            .setSortOption(.relevancy),
        ]

        #expect(actions.count == 5)
        #expect(actions[1] == .setSortOption(.relevancy))
        #expect(actions[4] == .setSortOption(.relevancy))
    }

    @Test("Simulate query update and search")
    func queryUpdateAndSearch() {
        let queries = ["S", "Sw", "Swi", "Swif", "Swift"]
        var actions: [SearchDomainAction] = []

        for query in queries {
            actions.append(.updateQuery(query))
        }
        actions.append(.search)

        #expect(actions.count == 6)
        #expect(actions.first == .updateQuery("S"))
        #expect(actions.last == .search)
    }

    @Test("Simulate clear results")
    func testClearResults() {
        let actions: [SearchDomainAction] = [
            .updateQuery("Query"),
            .search,
            .clearResults,
        ]

        #expect(actions.count == 3)
        #expect(actions[2] == .clearResults)
    }

    @Test("Simulate article selection from search results")
    func articleSelectionFromResults() {
        let articleIds = ["article-1", "article-2", "article-3"]
        var actions: [SearchDomainAction] = [
            .updateQuery("Test"),
            .search,
        ]

        for id in articleIds {
            actions.append(.selectArticle(articleId: id))
            actions.append(.clearSelectedArticle)
        }

        #expect(actions.count == 8)
    }
}
