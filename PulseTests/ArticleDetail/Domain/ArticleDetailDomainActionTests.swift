import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailDomainAction Lifecycle Tests")
struct ArticleDetailDomainActionLifecycleTests {
    @Test("Can create onAppear action")
    func onAppearAction() {
        let action1 = ArticleDetailDomainAction.onAppear
        let action2 = ArticleDetailDomainAction.onAppear
        #expect(action1 == action2)
    }
}

@Suite("ArticleDetailDomainAction Bookmark Tests")
struct ArticleDetailDomainActionBookmarkTests {
    @Test("Can create toggleBookmark action")
    func toggleBookmarkAction() {
        let action1 = ArticleDetailDomainAction.toggleBookmark
        let action2 = ArticleDetailDomainAction.toggleBookmark
        #expect(action1 == action2)
    }

    @Test("Can create bookmarkStatusLoaded action with true")
    func bookmarkStatusLoadedTrue() {
        let action = ArticleDetailDomainAction.bookmarkStatusLoaded(true)
        #expect(action == .bookmarkStatusLoaded(true))
    }

    @Test("Can create bookmarkStatusLoaded action with false")
    func bookmarkStatusLoadedFalse() {
        let action = ArticleDetailDomainAction.bookmarkStatusLoaded(false)
        #expect(action == .bookmarkStatusLoaded(false))
    }

    @Test("Different bookmark statuses create different actions")
    func differentBookmarkStatusesDifferent() {
        let action1 = ArticleDetailDomainAction.bookmarkStatusLoaded(true)
        let action2 = ArticleDetailDomainAction.bookmarkStatusLoaded(false)
        #expect(action1 != action2)
    }
}

@Suite("ArticleDetailDomainAction Share Sheet Tests")
struct ArticleDetailDomainActionShareSheetTests {
    @Test("Can create showShareSheet action")
    func showShareSheetAction() {
        let action1 = ArticleDetailDomainAction.showShareSheet
        let action2 = ArticleDetailDomainAction.showShareSheet
        #expect(action1 == action2)
    }

    @Test("Can create dismissShareSheet action")
    func dismissShareSheetAction() {
        let action1 = ArticleDetailDomainAction.dismissShareSheet
        let action2 = ArticleDetailDomainAction.dismissShareSheet
        #expect(action1 == action2)
    }

    @Test("showShareSheet and dismissShareSheet are different")
    func showAndDismissShareSheetDifferent() {
        let showAction = ArticleDetailDomainAction.showShareSheet
        let dismissAction = ArticleDetailDomainAction.dismissShareSheet
        #expect(showAction != dismissAction)
    }
}

@Suite("ArticleDetailDomainAction Browser Tests")
struct ArticleDetailDomainActionBrowserTests {
    @Test("Can create openInBrowser action")
    func openInBrowserAction() {
        let action1 = ArticleDetailDomainAction.openInBrowser
        let action2 = ArticleDetailDomainAction.openInBrowser
        #expect(action1 == action2)
    }

    @Test("openInBrowser action is repeatable")
    func openInBrowserRepeatable() {
        let actions = Array(repeating: ArticleDetailDomainAction.openInBrowser, count: 3)
        for action in actions {
            #expect(action == .openInBrowser)
        }
    }
}

@Suite("ArticleDetailDomainAction Content Processing Tests")
struct ArticleDetailDomainActionContentProcessingTests {
    @Test("Can create contentProcessingCompleted with content and description")
    func contentProcessingCompletedBoth() {
        let content = AttributedString("Article content")
        let description = AttributedString("Article description")
        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: content,
            description: description
        )
        #expect(action == .contentProcessingCompleted(content: content, description: description))
    }

    @Test("Can create contentProcessingCompleted with only content")
    func contentProcessingCompletedContentOnly() {
        let content = AttributedString("Content")
        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: content,
            description: nil
        )
        #expect(action == .contentProcessingCompleted(content: content, description: nil))
    }

    @Test("Can create contentProcessingCompleted with only description")
    func contentProcessingCompletedDescriptionOnly() {
        let description = AttributedString("Description")
        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: nil,
            description: description
        )
        #expect(action == .contentProcessingCompleted(content: nil, description: description))
    }

    @Test("Can create contentProcessingCompleted with neither")
    func contentProcessingCompletedNeither() {
        let action = ArticleDetailDomainAction.contentProcessingCompleted(
            content: nil,
            description: nil
        )
        #expect(action == .contentProcessingCompleted(content: nil, description: nil))
    }

    @Test("Different content values create different actions")
    func differentContentDifferentActions() {
        let action1 = ArticleDetailDomainAction.contentProcessingCompleted(
            content: AttributedString("Content 1"),
            description: nil
        )
        let action2 = ArticleDetailDomainAction.contentProcessingCompleted(
            content: AttributedString("Content 2"),
            description: nil
        )
        #expect(action1 != action2)
    }
}

@Suite("ArticleDetailDomainAction Summarization Sheet Tests")
struct ArticleDetailDomainActionSummarizationSheetTests {
    @Test("Can create showSummarizationSheet action")
    func showSummarizationSheetAction() {
        let action1 = ArticleDetailDomainAction.showSummarizationSheet
        let action2 = ArticleDetailDomainAction.showSummarizationSheet
        #expect(action1 == action2)
    }

    @Test("Can create dismissSummarizationSheet action")
    func dismissSummarizationSheetAction() {
        let action1 = ArticleDetailDomainAction.dismissSummarizationSheet
        let action2 = ArticleDetailDomainAction.dismissSummarizationSheet
        #expect(action1 == action2)
    }

    @Test("showSummarizationSheet and dismissSummarizationSheet are different")
    func showAndDismissSummarizationSheetDifferent() {
        let showAction = ArticleDetailDomainAction.showSummarizationSheet
        let dismissAction = ArticleDetailDomainAction.dismissSummarizationSheet
        #expect(showAction != dismissAction)
    }

    @Test("showSummarizationSheet and showShareSheet are different")
    func summarizationAndShareSheetDifferent() {
        let summaryAction = ArticleDetailDomainAction.showSummarizationSheet
        let shareAction = ArticleDetailDomainAction.showShareSheet
        #expect(summaryAction != shareAction)
    }
}

@Suite("ArticleDetailDomainAction Equatable Tests")
struct ArticleDetailDomainActionEquatableTests {
    @Test("Same simple actions are equal")
    func sameSimpleActionsEqual() {
        let action1 = ArticleDetailDomainAction.onAppear
        let action2 = ArticleDetailDomainAction.onAppear
        #expect(action1 == action2)
    }

    @Test("Different simple actions not equal")
    func differentSimpleActionsNotEqual() {
        let action1 = ArticleDetailDomainAction.onAppear
        let action2 = ArticleDetailDomainAction.toggleBookmark
        #expect(action1 != action2)
    }

    @Test("Actions with different associated values not equal")
    func differentAssociatedValuesNotEqual() {
        let action1 = ArticleDetailDomainAction.bookmarkStatusLoaded(true)
        let action2 = ArticleDetailDomainAction.bookmarkStatusLoaded(false)
        #expect(action1 != action2)
    }
}

@Suite("ArticleDetailDomainAction Complex Article Detail Workflow Tests")
struct ArticleDetailDomainActionComplexArticleDetailWorkflowTests {
    @Test("Simulate article view lifecycle")
    func articleViewLifecycle() {
        let content = AttributedString("Article content here")
        let description = AttributedString("Article description")

        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .contentProcessingCompleted(content: content, description: description),
            .toggleBookmark,
            .bookmarkStatusLoaded(true),
        ]

        #expect(actions.count == 4)
        #expect(actions.first == .onAppear)
    }

    @Test("Simulate bookmark toggle")
    func bookmarkToggle() {
        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .toggleBookmark,
            .bookmarkStatusLoaded(true),
        ]

        #expect(actions[1] == .toggleBookmark)
        #expect(actions[2] == .bookmarkStatusLoaded(true))
    }

    @Test("Simulate share sheet flow")
    func shareSheetFlow() {
        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .showShareSheet,
            .dismissShareSheet,
        ]

        #expect(actions.count == 3)
        #expect(actions[1] == .showShareSheet)
    }

    @Test("Simulate summarization sheet flow")
    func summarizationSheetFlow() {
        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .showSummarizationSheet,
            .dismissSummarizationSheet,
        ]

        #expect(actions.count == 3)
        #expect(actions[1] == .showSummarizationSheet)
    }

    @Test("Simulate open in browser")
    func testOpenInBrowser() {
        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .openInBrowser,
        ]

        #expect(actions[1] == .openInBrowser)
    }

    @Test("Simulate complete article interaction flow")
    func completeArticleFlow() {
        let content = AttributedString("Content")
        let description = AttributedString("Description")

        let actions: [ArticleDetailDomainAction] = [
            .onAppear,
            .contentProcessingCompleted(content: content, description: description),
            .toggleBookmark,
            .bookmarkStatusLoaded(true),
            .showShareSheet,
            .dismissShareSheet,
            .showSummarizationSheet,
            .dismissSummarizationSheet,
        ]

        #expect(actions.count == 8)
        #expect(actions.first == .onAppear)
    }

    @Test("Simulate multiple sheet presentations")
    func multipleSheetPresentations() {
        let actions: [ArticleDetailDomainAction] = [
            .showShareSheet,
            .dismissShareSheet,
            .showSummarizationSheet,
            .dismissSummarizationSheet,
            .showShareSheet,
            .dismissShareSheet,
        ]

        #expect(actions.count == 6)
    }
}
