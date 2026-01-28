import Foundation
@testable import Pulse
import Testing

@Suite("HomeDomainAction Tests")
struct HomeDomainActionTests {
    // MARK: - Action Case Tests

    @Test("loadInitialData action exists")
    func loadInitialDataAction() {
        let action = HomeDomainAction.loadInitialData
        #expect(action == .loadInitialData)
    }

    @Test("loadMoreHeadlines action exists")
    func loadMoreHeadlinesAction() {
        let action = HomeDomainAction.loadMoreHeadlines
        #expect(action == .loadMoreHeadlines)
    }

    @Test("refresh action exists")
    func refreshAction() {
        let action = HomeDomainAction.refresh
        #expect(action == .refresh)
    }

    @Test("selectArticle action with article ID")
    func selectArticleAction() {
        let action = HomeDomainAction.selectArticle(articleId: "article-123")

        if case let .selectArticle(articleId) = action {
            #expect(articleId == "article-123")
        } else {
            Issue.record("Expected selectArticle action")
        }
    }

    @Test("clearSelectedArticle action exists")
    func clearSelectedArticleAction() {
        let action = HomeDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    @Test("bookmarkArticle action with article ID")
    func bookmarkArticleAction() {
        let action = HomeDomainAction.bookmarkArticle(articleId: "article-456")

        if case let .bookmarkArticle(articleId) = action {
            #expect(articleId == "article-456")
        } else {
            Issue.record("Expected bookmarkArticle action")
        }
    }

    @Test("shareArticle action with article ID")
    func shareArticleAction() {
        let action = HomeDomainAction.shareArticle(articleId: "article-789")

        if case let .shareArticle(articleId) = action {
            #expect(articleId == "article-789")
        } else {
            Issue.record("Expected shareArticle action")
        }
    }

    @Test("clearArticleToShare action exists")
    func clearArticleToShareAction() {
        let action = HomeDomainAction.clearArticleToShare
        #expect(action == .clearArticleToShare)
    }

    @Test("selectCategory action with category")
    func selectCategoryAction() {
        let action = HomeDomainAction.selectCategory(.technology)

        if case let .selectCategory(category) = action {
            #expect(category == .technology)
        } else {
            Issue.record("Expected selectCategory action")
        }
    }

    @Test("selectCategory action with nil")
    func selectCategoryNilAction() {
        let action = HomeDomainAction.selectCategory(nil)

        if case let .selectCategory(category) = action {
            #expect(category == nil)
        } else {
            Issue.record("Expected selectCategory action with nil")
        }
    }

    // MARK: - Equatable Tests

    @Test("Same simple actions are equal")
    func sameSimpleActionsAreEqual() {
        #expect(HomeDomainAction.loadInitialData == HomeDomainAction.loadInitialData)
        #expect(HomeDomainAction.loadMoreHeadlines == HomeDomainAction.loadMoreHeadlines)
        #expect(HomeDomainAction.refresh == HomeDomainAction.refresh)
        #expect(HomeDomainAction.clearSelectedArticle == HomeDomainAction.clearSelectedArticle)
        #expect(HomeDomainAction.clearArticleToShare == HomeDomainAction.clearArticleToShare)
    }

    @Test("Different simple actions are not equal")
    func differentSimpleActionsAreNotEqual() {
        #expect(HomeDomainAction.loadInitialData != HomeDomainAction.loadMoreHeadlines)
        #expect(HomeDomainAction.refresh != HomeDomainAction.clearSelectedArticle)
    }

    @Test("selectArticle with same ID are equal")
    func selectArticleSameIdAreEqual() {
        #expect(
            HomeDomainAction.selectArticle(articleId: "article-123") ==
                HomeDomainAction.selectArticle(articleId: "article-123")
        )
    }

    @Test("selectArticle with different IDs are not equal")
    func selectArticleDifferentIdsAreNotEqual() {
        #expect(
            HomeDomainAction.selectArticle(articleId: "article-123") !=
                HomeDomainAction.selectArticle(articleId: "article-456")
        )
    }

    @Test("bookmarkArticle with same ID are equal")
    func bookmarkArticleSameIdAreEqual() {
        #expect(
            HomeDomainAction.bookmarkArticle(articleId: "article-123") ==
                HomeDomainAction.bookmarkArticle(articleId: "article-123")
        )
    }

    @Test("bookmarkArticle with different IDs are not equal")
    func bookmarkArticleDifferentIdsAreNotEqual() {
        #expect(
            HomeDomainAction.bookmarkArticle(articleId: "article-123") !=
                HomeDomainAction.bookmarkArticle(articleId: "article-456")
        )
    }

    @Test("shareArticle with same ID are equal")
    func shareArticleSameIdAreEqual() {
        #expect(
            HomeDomainAction.shareArticle(articleId: "article-123") ==
                HomeDomainAction.shareArticle(articleId: "article-123")
        )
    }

    @Test("shareArticle with different IDs are not equal")
    func shareArticleDifferentIdsAreNotEqual() {
        #expect(
            HomeDomainAction.shareArticle(articleId: "article-123") !=
                HomeDomainAction.shareArticle(articleId: "article-456")
        )
    }

    @Test("selectCategory with same category are equal")
    func selectCategorySameCategoryAreEqual() {
        #expect(
            HomeDomainAction.selectCategory(.technology) ==
                HomeDomainAction.selectCategory(.technology)
        )
    }

    @Test("selectCategory with different categories are not equal")
    func selectCategoryDifferentCategoriesAreNotEqual() {
        #expect(
            HomeDomainAction.selectCategory(.technology) !=
                HomeDomainAction.selectCategory(.business)
        )
    }

    @Test("selectCategory nil and non-nil are not equal")
    func selectCategoryNilAndNonNilAreNotEqual() {
        #expect(
            HomeDomainAction.selectCategory(nil) !=
                HomeDomainAction.selectCategory(.technology)
        )
    }

    @Test("Different action types with same string are not equal")
    func differentActionTypesNotEqual() {
        #expect(
            HomeDomainAction.selectArticle(articleId: "id") !=
                HomeDomainAction.bookmarkArticle(articleId: "id")
        )
    }
}
