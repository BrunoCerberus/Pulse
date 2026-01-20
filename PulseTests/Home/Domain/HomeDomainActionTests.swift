import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainAction Initialization Tests")
struct HomeDomainActionInitializationTests {
    @Test("Can create loadInitialData action")
    func loadInitialDataAction() {
        let action = HomeDomainAction.loadInitialData
        #expect(action == .loadInitialData)
    }

    @Test("Can create loadMoreHeadlines action")
    func loadMoreHeadlinesAction() {
        let action = HomeDomainAction.loadMoreHeadlines
        #expect(action == .loadMoreHeadlines)
    }

    @Test("Can create refresh action")
    func testRefreshAction() {
        let action = HomeDomainAction.refresh
        #expect(action == .refresh)
    }

    @Test("Can create selectArticle action with ID")
    func selectArticleAction() {
        let action = HomeDomainAction.selectArticle(articleId: "article-123")
        #expect(action == .selectArticle(articleId: "article-123"))
    }

    @Test("Can create clearSelectedArticle action")
    func clearSelectedArticleAction() {
        let action = HomeDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    @Test("Can create bookmarkArticle action with ID")
    func bookmarkArticleAction() {
        let action = HomeDomainAction.bookmarkArticle(articleId: "article-123")
        #expect(action == .bookmarkArticle(articleId: "article-123"))
    }

    @Test("Can create shareArticle action with ID")
    func shareArticleAction() {
        let action = HomeDomainAction.shareArticle(articleId: "article-123")
        #expect(action == .shareArticle(articleId: "article-123"))
    }

    @Test("Can create clearArticleToShare action")
    func clearArticleToShareAction() {
        let action = HomeDomainAction.clearArticleToShare
        #expect(action == .clearArticleToShare)
    }
}

@Suite("HomeDomainAction Data Loading Actions Tests")
struct HomeDomainActionDataLoadingTests {
    @Test("loadInitialData action is repeatable")
    func loadInitialDataRepeatable() {
        let action1 = HomeDomainAction.loadInitialData
        let action2 = HomeDomainAction.loadInitialData
        #expect(action1 == action2)
    }

    @Test("loadMoreHeadlines action is repeatable")
    func loadMoreHeadlinesRepeatable() {
        let action1 = HomeDomainAction.loadMoreHeadlines
        let action2 = HomeDomainAction.loadMoreHeadlines
        #expect(action1 == action2)
    }

    @Test("refresh action is repeatable")
    func refreshRepeatable() {
        let action1 = HomeDomainAction.refresh
        let action2 = HomeDomainAction.refresh
        #expect(action1 == action2)
    }

    @Test("Different data loading actions are not equal")
    func differentDataLoadingActionsNotEqual() {
        let action1 = HomeDomainAction.loadInitialData
        let action2 = HomeDomainAction.loadMoreHeadlines
        let action3 = HomeDomainAction.refresh
        #expect(action1 != action2)
        #expect(action2 != action3)
        #expect(action1 != action3)
    }
}

@Suite("HomeDomainAction Article Selection Tests")
struct HomeDomainActionArticleSelectionTests {
    @Test("selectArticle preserves article ID")
    func selectArticlePreservesID() {
        let id = "world/2024/jan/01/article"
        let action = HomeDomainAction.selectArticle(articleId: id)
        #expect(action == .selectArticle(articleId: id))
    }

    @Test("Different article IDs create different actions")
    func differentArticleIDsDifferentActions() {
        let action1 = HomeDomainAction.selectArticle(articleId: "article-1")
        let action2 = HomeDomainAction.selectArticle(articleId: "article-2")
        #expect(action1 != action2)
    }

    @Test("selectArticle with empty ID")
    func selectArticleEmptyID() {
        let action = HomeDomainAction.selectArticle(articleId: "")
        #expect(action == .selectArticle(articleId: ""))
    }

    @Test("selectArticle with special characters")
    func selectArticleSpecialCharacters() {
        let id = "article/with/slashes/and-dashes_and_underscores"
        let action = HomeDomainAction.selectArticle(articleId: id)
        #expect(action == .selectArticle(articleId: id))
    }

    @Test("clearSelectedArticle action")
    func testClearSelectedArticle() {
        let action1 = HomeDomainAction.clearSelectedArticle
        let action2 = HomeDomainAction.clearSelectedArticle
        #expect(action1 == action2)
    }

    @Test("clearSelectedArticle different from selectArticle")
    func clearDifferentFromSelect() {
        let selectAction = HomeDomainAction.selectArticle(articleId: "article-1")
        let clearAction = HomeDomainAction.clearSelectedArticle
        #expect(selectAction != clearAction)
    }
}

@Suite("HomeDomainAction Bookmark Action Tests")
struct HomeDomainActionBookmarkActionTests {
    @Test("bookmarkArticle preserves article ID")
    func bookmarkArticlePreservesID() {
        let id = "article-123"
        let action = HomeDomainAction.bookmarkArticle(articleId: id)
        #expect(action == .bookmarkArticle(articleId: id))
    }

    @Test("Different article IDs create different bookmark actions")
    func differentIDsDifferentBookmarkActions() {
        let action1 = HomeDomainAction.bookmarkArticle(articleId: "article-1")
        let action2 = HomeDomainAction.bookmarkArticle(articleId: "article-2")
        #expect(action1 != action2)
    }

    @Test("bookmarkArticle with empty ID")
    func bookmarkArticleEmptyID() {
        let action = HomeDomainAction.bookmarkArticle(articleId: "")
        #expect(action == .bookmarkArticle(articleId: ""))
    }

    @Test("bookmarkArticle different from other actions")
    func bookmarkDifferentFromOthers() {
        let bookmarkAction = HomeDomainAction.bookmarkArticle(articleId: "article-1")
        let selectAction = HomeDomainAction.selectArticle(articleId: "article-1")
        let refreshAction = HomeDomainAction.refresh
        #expect(bookmarkAction != selectAction)
        #expect(bookmarkAction != refreshAction)
    }
}

@Suite("HomeDomainAction Share Action Tests")
struct HomeDomainActionShareActionTests {
    @Test("shareArticle preserves article ID")
    func shareArticlePreservesID() {
        let id = "article-456"
        let action = HomeDomainAction.shareArticle(articleId: id)
        #expect(action == .shareArticle(articleId: id))
    }

    @Test("Different article IDs create different share actions")
    func differentIDsDifferentShareActions() {
        let action1 = HomeDomainAction.shareArticle(articleId: "article-1")
        let action2 = HomeDomainAction.shareArticle(articleId: "article-2")
        #expect(action1 != action2)
    }

    @Test("shareArticle with empty ID")
    func shareArticleEmptyID() {
        let action = HomeDomainAction.shareArticle(articleId: "")
        #expect(action == .shareArticle(articleId: ""))
    }

    @Test("clearArticleToShare action")
    func testClearArticleToShare() {
        let action1 = HomeDomainAction.clearArticleToShare
        let action2 = HomeDomainAction.clearArticleToShare
        #expect(action1 == action2)
    }

    @Test("clearArticleToShare different from shareArticle")
    func clearShareDifferentFromShare() {
        let shareAction = HomeDomainAction.shareArticle(articleId: "article-1")
        let clearAction = HomeDomainAction.clearArticleToShare
        #expect(shareAction != clearAction)
    }
}

@Suite("HomeDomainAction Equatable Tests")
struct HomeDomainActionEquatableTests {
    @Test("Same action instances are equal")
    func sameActionsEqual() {
        let action1 = HomeDomainAction.loadInitialData
        let action2 = HomeDomainAction.loadInitialData
        #expect(action1 == action2)
    }

    @Test("Different action types are not equal")
    func differentActionTypesNotEqual() {
        let loadAction = HomeDomainAction.loadInitialData
        let refreshAction = HomeDomainAction.refresh
        #expect(loadAction != refreshAction)
    }

    @Test("Action with different associated values not equal")
    func differentAssociatedValuesNotEqual() {
        let action1 = HomeDomainAction.selectArticle(articleId: "article-1")
        let action2 = HomeDomainAction.selectArticle(articleId: "article-2")
        #expect(action1 != action2)
    }

    @Test("Action with same associated values equal")
    func sameAssociatedValuesEqual() {
        let action1 = HomeDomainAction.bookmarkArticle(articleId: "article-1")
        let action2 = HomeDomainAction.bookmarkArticle(articleId: "article-1")
        #expect(action1 == action2)
    }
}

@Suite("HomeDomainAction User Interaction Workflow Tests")
struct HomeDomainActionUserInteractionWorkflowTests {
    @Test("Simulate initial data load workflow")
    func initialDataLoadWorkflow() {
        let actions: [HomeDomainAction] = [
            .loadInitialData,
        ]
        #expect(actions.first == .loadInitialData)
    }

    @Test("Simulate article selection workflow")
    func articleSelectionWorkflow() {
        let actions: [HomeDomainAction] = [
            .loadInitialData,
            .selectArticle(articleId: "article-1"),
            .clearSelectedArticle,
        ]
        #expect(actions[0] == .loadInitialData)
        #expect(actions[1] == .selectArticle(articleId: "article-1"))
        #expect(actions[2] == .clearSelectedArticle)
    }

    @Test("Simulate article sharing workflow")
    func articleSharingWorkflow() {
        let actions: [HomeDomainAction] = [
            .shareArticle(articleId: "article-1"),
            .clearArticleToShare,
        ]
        #expect(actions.count == 2)
        #expect(actions[0] == .shareArticle(articleId: "article-1"))
    }

    @Test("Simulate bookmark workflow")
    func bookmarkWorkflow() {
        let actions: [HomeDomainAction] = [
            .selectArticle(articleId: "article-1"),
            .bookmarkArticle(articleId: "article-1"),
            .clearSelectedArticle,
        ]
        #expect(actions.count == 3)
        #expect(actions[1] == .bookmarkArticle(articleId: "article-1"))
    }

    @Test("Simulate refresh workflow")
    func refreshWorkflow() {
        let actions: [HomeDomainAction] = [
            .refresh,
            .clearSelectedArticle,
        ]
        #expect(actions.first == .refresh)
    }

    @Test("Simulate pagination workflow")
    func paginationWorkflow() {
        let actions: [HomeDomainAction] = [
            .loadInitialData,
            .loadMoreHeadlines,
            .loadMoreHeadlines,
        ]
        #expect(actions.count == 3)
        #expect(actions[1] == .loadMoreHeadlines)
    }

    @Test("Multiple bookmark actions for different articles")
    func multipleBookmarkActions() {
        let articleIds = ["article-1", "article-2", "article-3"]
        let actions = articleIds.map { HomeDomainAction.bookmarkArticle(articleId: $0) }

        #expect(actions.count == 3)
        #expect(actions[0] == .bookmarkArticle(articleId: "article-1"))
        #expect(actions[1] == .bookmarkArticle(articleId: "article-2"))
        #expect(actions[2] == .bookmarkArticle(articleId: "article-3"))
    }
}
