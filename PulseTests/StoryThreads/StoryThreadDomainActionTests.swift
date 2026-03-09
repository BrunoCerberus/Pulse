import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadDomainAction Tests")
struct StoryThreadDomainActionTests {
    private let testID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let testID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    // MARK: - Action Case Tests

    @Test("loadFollowedThreads action exists")
    func loadFollowedThreadsAction() {
        let action = StoryThreadDomainAction.loadFollowedThreads
        #expect(action == .loadFollowedThreads)
    }

    @Test("loadThreadsForArticle action with article ID")
    func loadThreadsForArticleAction() {
        let action = StoryThreadDomainAction.loadThreadsForArticle(articleID: "article-123")

        if case let .loadThreadsForArticle(articleID) = action {
            #expect(articleID == "article-123")
        } else {
            Issue.record("Expected loadThreadsForArticle action")
        }
    }

    @Test("followThread action with UUID")
    func followThreadAction() {
        let action = StoryThreadDomainAction.followThread(id: testID)

        if case let .followThread(id) = action {
            #expect(id == testID)
        } else {
            Issue.record("Expected followThread action")
        }
    }

    @Test("unfollowThread action with UUID")
    func unfollowThreadAction() {
        let action = StoryThreadDomainAction.unfollowThread(id: testID)

        if case let .unfollowThread(id) = action {
            #expect(id == testID)
        } else {
            Issue.record("Expected unfollowThread action")
        }
    }

    @Test("generateSummary action with thread ID")
    func generateSummaryAction() {
        let action = StoryThreadDomainAction.generateSummary(threadID: testID)

        if case let .generateSummary(threadID) = action {
            #expect(threadID == testID)
        } else {
            Issue.record("Expected generateSummary action")
        }
    }

    @Test("markThreadAsRead action with UUID")
    func markThreadAsReadAction() {
        let action = StoryThreadDomainAction.markThreadAsRead(id: testID)

        if case let .markThreadAsRead(id) = action {
            #expect(id == testID)
        } else {
            Issue.record("Expected markThreadAsRead action")
        }
    }

    @Test("refresh action exists")
    func refreshAction() {
        let action = StoryThreadDomainAction.refresh
        #expect(action == .refresh)
    }

    // MARK: - Equatable Tests

    @Test("Same simple actions are equal")
    func sameSimpleActionsAreEqual() {
        #expect(StoryThreadDomainAction.loadFollowedThreads == StoryThreadDomainAction.loadFollowedThreads)
        #expect(StoryThreadDomainAction.refresh == StoryThreadDomainAction.refresh)
    }

    @Test("Different simple actions are not equal")
    func differentSimpleActionsAreNotEqual() {
        #expect(StoryThreadDomainAction.loadFollowedThreads != StoryThreadDomainAction.refresh)
    }

    @Test("Actions with same associated values are equal")
    func actionsWithSameValuesAreEqual() {
        #expect(
            StoryThreadDomainAction.followThread(id: testID) ==
                StoryThreadDomainAction.followThread(id: testID)
        )
        #expect(
            StoryThreadDomainAction.loadThreadsForArticle(articleID: "abc") ==
                StoryThreadDomainAction.loadThreadsForArticle(articleID: "abc")
        )
        #expect(
            StoryThreadDomainAction.generateSummary(threadID: testID) ==
                StoryThreadDomainAction.generateSummary(threadID: testID)
        )
    }

    @Test("Actions with different associated values are not equal")
    func actionsWithDifferentValuesAreNotEqual() {
        #expect(
            StoryThreadDomainAction.followThread(id: testID) !=
                StoryThreadDomainAction.followThread(id: testID2)
        )
        #expect(
            StoryThreadDomainAction.loadThreadsForArticle(articleID: "abc") !=
                StoryThreadDomainAction.loadThreadsForArticle(articleID: "def")
        )
    }

    @Test("Simple actions not equal to actions with associated values")
    func simpleActionsNotEqualToAssociatedValueActions() {
        #expect(StoryThreadDomainAction.loadFollowedThreads != StoryThreadDomainAction.followThread(id: testID))
        #expect(StoryThreadDomainAction.refresh != StoryThreadDomainAction.markThreadAsRead(id: testID))
    }

    // MARK: - Associated Value Preservation Tests

    @Test("loadThreadsForArticle preserves article ID")
    func loadThreadsForArticlePreservesArticleId() {
        let testIds = ["id-1", "id-2", "long-article-id-string", ""]

        for id in testIds {
            let action = StoryThreadDomainAction.loadThreadsForArticle(articleID: id)
            if case let .loadThreadsForArticle(articleID) = action {
                #expect(articleID == id)
            } else {
                Issue.record("Expected loadThreadsForArticle action for ID: \(id)")
            }
        }
    }
}
