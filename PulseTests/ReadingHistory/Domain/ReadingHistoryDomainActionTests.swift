import Foundation
@testable import Pulse
import Testing

@Suite("ReadingHistoryDomainAction Tests")
struct ReadingHistoryDomainActionTests {
    // MARK: - Action Case Tests

    @Test("loadHistory action exists")
    func loadHistoryAction() {
        let action = ReadingHistoryDomainAction.loadHistory
        #expect(action == .loadHistory)
    }

    @Test("clearHistory action exists")
    func clearHistoryAction() {
        let action = ReadingHistoryDomainAction.clearHistory
        #expect(action == .clearHistory)
    }

    @Test("selectArticle action with article ID")
    func selectArticleAction() {
        let action = ReadingHistoryDomainAction.selectArticle(articleId: "article-456")

        if case let .selectArticle(articleId) = action {
            #expect(articleId == "article-456")
        } else {
            Issue.record("Expected selectArticle action")
        }
    }

    @Test("clearSelectedArticle action exists")
    func clearSelectedArticleAction() {
        let action = ReadingHistoryDomainAction.clearSelectedArticle
        #expect(action == .clearSelectedArticle)
    }

    // MARK: - Equatable Tests

    @Test("Same simple actions are equal")
    func sameSimpleActionsAreEqual() {
        #expect(ReadingHistoryDomainAction.loadHistory == ReadingHistoryDomainAction.loadHistory)
        #expect(ReadingHistoryDomainAction.clearHistory == ReadingHistoryDomainAction.clearHistory)
        #expect(ReadingHistoryDomainAction.clearSelectedArticle == ReadingHistoryDomainAction.clearSelectedArticle)
    }

    @Test("Different simple actions are not equal")
    func differentSimpleActionsAreNotEqual() {
        #expect(ReadingHistoryDomainAction.loadHistory != ReadingHistoryDomainAction.clearHistory)
        #expect(ReadingHistoryDomainAction.clearHistory != ReadingHistoryDomainAction.clearSelectedArticle)
        #expect(ReadingHistoryDomainAction.loadHistory != ReadingHistoryDomainAction.clearSelectedArticle)
    }

    @Test("Simple actions not equal to actions with associated values")
    func simpleActionsNotEqualToAssociatedValueActions() {
        #expect(ReadingHistoryDomainAction.loadHistory != ReadingHistoryDomainAction.selectArticle(articleId: "1"))
        #expect(ReadingHistoryDomainAction.clearHistory != ReadingHistoryDomainAction.selectArticle(articleId: "1"))
    }

    @Test("selectArticle with same article ID are equal")
    func selectArticleSameIdAreEqual() {
        #expect(
            ReadingHistoryDomainAction.selectArticle(articleId: "article-123") ==
                ReadingHistoryDomainAction.selectArticle(articleId: "article-123")
        )
    }

    @Test("selectArticle with different article IDs are not equal")
    func selectArticleDifferentIdsAreNotEqual() {
        #expect(
            ReadingHistoryDomainAction.selectArticle(articleId: "article-123") !=
                ReadingHistoryDomainAction.selectArticle(articleId: "article-456")
        )
    }

    // MARK: - Action Properties Tests

    @Test("selectArticle preserves article ID")
    func selectArticlePreservesArticleId() {
        let testIds = ["id-1", "id-2", "long-article-id-string", ""]

        for id in testIds {
            let action = ReadingHistoryDomainAction.selectArticle(articleId: id)
            if case let .selectArticle(articleId) = action {
                #expect(articleId == id)
            } else {
                Issue.record("Expected selectArticle action for ID: \(id)")
            }
        }
    }
}
