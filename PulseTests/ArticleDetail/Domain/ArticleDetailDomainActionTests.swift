import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainAction Tests")
struct ArticleDetailDomainActionTests {
    private var testArticle: Article {
        Article(
            id: "test-article-1",
            title: "Test Article Title",
            source: ArticleSource(id: "test-source", name: "Test Source"),
            url: "https://example.com/article",
            publishedAt: Date(),
            category: .technology
        )
    }

    // MARK: - Lifecycle Tests

    @Test("onAppear action exists")
    func onAppearAction() {
        let action = ArticleDetailDomainAction.onAppear
        #expect(action == .onAppear)
    }

    // MARK: - Bookmark Tests

    @Test("toggleBookmark action exists")
    func toggleBookmarkAction() {
        let action = ArticleDetailDomainAction.toggleBookmark
        #expect(action == .toggleBookmark)
    }

    @Test("bookmarkStatusLoaded action with true")
    func bookmarkStatusLoadedTrue() {
        let action = ArticleDetailDomainAction.bookmarkStatusLoaded(true)

        if case let .bookmarkStatusLoaded(isBookmarked) = action {
            #expect(isBookmarked == true)
        } else {
            Issue.record("Expected bookmarkStatusLoaded action")
        }
    }

    @Test("bookmarkStatusLoaded action with false")
    func bookmarkStatusLoadedFalse() {
        let action = ArticleDetailDomainAction.bookmarkStatusLoaded(false)

        if case let .bookmarkStatusLoaded(isBookmarked) = action {
            #expect(isBookmarked == false)
        } else {
            Issue.record("Expected bookmarkStatusLoaded action")
        }
    }

    // MARK: - Share Sheet Tests

    @Test("showShareSheet action exists")
    func showShareSheetAction() {
        let action = ArticleDetailDomainAction.showShareSheet
        #expect(action == .showShareSheet)
    }

    @Test("dismissShareSheet action exists")
    func dismissShareSheetAction() {
        let action = ArticleDetailDomainAction.dismissShareSheet
        #expect(action == .dismissShareSheet)
    }

    // MARK: - Browser Tests

    @Test("openInBrowser action exists")
    func openInBrowserAction() {
        let action = ArticleDetailDomainAction.openInBrowser
        #expect(action == .openInBrowser)
    }

    // MARK: - Content Processing Tests

    @Test("contentProcessingCompleted action with content")
    func contentProcessingCompletedWithContent() throws {
        let content = try AttributedString(markdown: "**Content**")
        let description = try AttributedString(markdown: "*Description*")

        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: content,
            description: description
        )

        if case let .contentProcessingCompleted(actionContent, actionDescription) = action {
            #expect(actionContent != nil)
            #expect(actionDescription != nil)
            let contentString = actionContent.map { String($0.characters) } ?? ""
            #expect(contentString.contains("Content"))
        } else {
            Issue.record("Expected contentProcessingCompleted action")
        }
    }

    @Test("contentProcessingCompleted action with nil values")
    func contentProcessingCompletedWithNil() {
        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: nil,
            description: nil
        )

        if case let .contentProcessingCompleted(actionContent, actionDescription) = action {
            #expect(actionContent == nil)
            #expect(actionDescription == nil)
        } else {
            Issue.record("Expected contentProcessingCompleted action")
        }
    }

    // MARK: - Summarization Tests

    @Test("showSummarizationSheet action exists")
    func showSummarizationSheetAction() {
        let action = ArticleDetailDomainAction.showSummarizationSheet
        #expect(action == .showSummarizationSheet)
    }

    @Test("dismissSummarizationSheet action exists")
    func dismissSummarizationSheetAction() {
        let action = ArticleDetailDomainAction.dismissSummarizationSheet
        #expect(action == .dismissSummarizationSheet)
    }

    // MARK: - Equatable Tests

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(ArticleDetailDomainAction.onAppear == ArticleDetailDomainAction.onAppear)
        #expect(ArticleDetailDomainAction.toggleBookmark == ArticleDetailDomainAction.toggleBookmark)
        #expect(ArticleDetailDomainAction.showShareSheet == ArticleDetailDomainAction.showShareSheet)
        #expect(ArticleDetailDomainAction.dismissShareSheet == ArticleDetailDomainAction.dismissShareSheet)
        #expect(ArticleDetailDomainAction.openInBrowser == ArticleDetailDomainAction.openInBrowser)
        #expect(ArticleDetailDomainAction.showSummarizationSheet == ArticleDetailDomainAction.showSummarizationSheet)
        #expect(ArticleDetailDomainAction.dismissSummarizationSheet == ArticleDetailDomainAction.dismissSummarizationSheet)
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(ArticleDetailDomainAction.onAppear != ArticleDetailDomainAction.toggleBookmark)
        #expect(ArticleDetailDomainAction.showShareSheet != ArticleDetailDomainAction.dismissShareSheet)
        #expect(ArticleDetailDomainAction.openInBrowser != ArticleDetailDomainAction.onAppear)
    }

    @Test("bookmarkStatusLoaded with different values are not equal")
    func bookmarkStatusLoadedDifferentValues() {
        #expect(
            ArticleDetailDomainAction.bookmarkStatusLoaded(true) !=
                ArticleDetailDomainAction.bookmarkStatusLoaded(false)
        )
    }

    @Test("bookmarkStatusLoaded with same values are equal")
    func bookmarkStatusLoadedSameValues() {
        #expect(
            ArticleDetailDomainAction.bookmarkStatusLoaded(true) ==
                ArticleDetailDomainAction.bookmarkStatusLoaded(true)
        )
        #expect(
            ArticleDetailDomainAction.bookmarkStatusLoaded(false) ==
                ArticleDetailDomainAction.bookmarkStatusLoaded(false)
        )
    }
}
