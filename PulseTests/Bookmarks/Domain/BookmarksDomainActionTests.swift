import Foundation
@testable import Pulse
import Testing

@Suite("BookmarksDomainAction Tests")
struct BookmarksDomainActionTests {
    // MARK: - Action Case Tests

    @Test("loadBookmarks action exists")
    func loadBookmarksAction() {
        let action = BookmarksDomainAction.loadBookmarks
        #expect(action == .loadBookmarks)
    }

    @Test("refresh action exists")
    func refreshAction() {
        let action = BookmarksDomainAction.refresh
        #expect(action == .refresh)
    }

    @Test("removeBookmark action with article ID")
    func removeBookmarkAction() {
        let action = BookmarksDomainAction.removeBookmark(articleId: "article-123")

        if case let .removeBookmark(articleId) = action {
            #expect(articleId == "article-123")
        } else {
            Issue.record("Expected removeBookmark action")
        }
    }

    @Test("selectArticle action with article ID")
    func selectArticleAction() {
        let action = BookmarksDomainAction.selectArticle(articleId: "article-456")

        if case let .selectArticle(articleId) = action {
            #expect(articleId == "article-456")
        } else {
            Issue.record("Expected selectArticle action")
        }
    }

    @Test("clearSelectedArticle action exists")
    func clearSelectedArticleAction() {
        let action = BookmarksDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    // MARK: - Equatable Tests

    @Test("Same simple actions are equal")
    func sameSimpleActionsAreEqual() {
        #expect(BookmarksDomainAction.loadBookmarks == BookmarksDomainAction.loadBookmarks)
        #expect(BookmarksDomainAction.refresh == BookmarksDomainAction.refresh)
        #expect(BookmarksDomainAction.clearSelectedArticle == BookmarksDomainAction.clearSelectedArticle)
    }

    @Test("Different simple actions are not equal")
    func differentSimpleActionsAreNotEqual() {
        #expect(BookmarksDomainAction.loadBookmarks != BookmarksDomainAction.refresh)
        #expect(BookmarksDomainAction.refresh != BookmarksDomainAction.clearSelectedArticle)
        #expect(BookmarksDomainAction.loadBookmarks != BookmarksDomainAction.clearSelectedArticle)
    }

    @Test("Simple actions not equal to actions with associated values")
    func simpleActionsNotEqualToAssociatedValueActions() {
        #expect(BookmarksDomainAction.loadBookmarks != BookmarksDomainAction.removeBookmark(articleId: "1"))
        #expect(BookmarksDomainAction.refresh != BookmarksDomainAction.selectArticle(articleId: "1"))
    }

    @Test("removeBookmark with same article ID are equal")
    func removeBookmarkSameIdAreEqual() {
        #expect(
            BookmarksDomainAction.removeBookmark(articleId: "article-123") ==
                BookmarksDomainAction.removeBookmark(articleId: "article-123")
        )
    }

    @Test("removeBookmark with different article IDs are not equal")
    func removeBookmarkDifferentIdsAreNotEqual() {
        #expect(
            BookmarksDomainAction.removeBookmark(articleId: "article-123") !=
                BookmarksDomainAction.removeBookmark(articleId: "article-456")
        )
    }

    @Test("selectArticle with same article ID are equal")
    func selectArticleSameIdAreEqual() {
        #expect(
            BookmarksDomainAction.selectArticle(articleId: "article-123") ==
                BookmarksDomainAction.selectArticle(articleId: "article-123")
        )
    }

    @Test("selectArticle with different article IDs are not equal")
    func selectArticleDifferentIdsAreNotEqual() {
        #expect(
            BookmarksDomainAction.selectArticle(articleId: "article-123") !=
                BookmarksDomainAction.selectArticle(articleId: "article-456")
        )
    }

    @Test("removeBookmark not equal to selectArticle even with same ID")
    func removeBookmarkNotEqualToSelectArticle() {
        #expect(
            BookmarksDomainAction.removeBookmark(articleId: "article-123") !=
                BookmarksDomainAction.selectArticle(articleId: "article-123")
        )
    }

    // MARK: - Action Properties Tests

    @Test("removeBookmark preserves article ID")
    func removeBookmarkPreservesArticleId() {
        let testIds = ["id-1", "id-2", "long-article-id-string", ""]

        for id in testIds {
            let action = BookmarksDomainAction.removeBookmark(articleId: id)
            if case let .removeBookmark(articleId) = action {
                #expect(articleId == id)
            } else {
                Issue.record("Expected removeBookmark action for ID: \(id)")
            }
        }
    }

    @Test("selectArticle preserves article ID")
    func selectArticlePreservesArticleId() {
        let testIds = ["id-1", "id-2", "long-article-id-string", ""]

        for id in testIds {
            let action = BookmarksDomainAction.selectArticle(articleId: id)
            if case let .selectArticle(articleId) = action {
                #expect(articleId == id)
            } else {
                Issue.record("Expected selectArticle action for ID: \(id)")
            }
        }
    }
}
