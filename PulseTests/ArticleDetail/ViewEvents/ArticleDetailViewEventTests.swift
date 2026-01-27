import Foundation
@testable import Pulse
import Testing

@Suite("ArticleDetailViewEvent Tests")
struct ArticleDetailViewEventTests {
    @Test("onAppear event") func onAppear() {
        #expect(ArticleDetailViewEvent.onAppear == .onAppear)
    }

    @Test("onBookmarkTapped event") func onBookmarkTapped() {
        #expect(ArticleDetailViewEvent.onBookmarkTapped == .onBookmarkTapped)
    }

    @Test("onShareTapped event") func onShareTapped() {
        #expect(ArticleDetailViewEvent.onShareTapped == .onShareTapped)
    }

    @Test("onDismissShareSheet event") func onDismissShareSheet() {
        #expect(ArticleDetailViewEvent.onDismissShareSheet == .onDismissShareSheet)
    }

    @Test("onOpenInBrowser event") func onOpenInBrowser() {
        #expect(ArticleDetailViewEvent.onOpenInBrowser == .onOpenInBrowser)
    }

    @Test("onSummarizeTapped event") func onSummarizeTapped() {
        #expect(ArticleDetailViewEvent.onSummarizeTapped == .onSummarizeTapped)
    }

    @Test("onDismissSummarization event") func onDismissSummarization() {
        #expect(ArticleDetailViewEvent.onDismissSummarization == .onDismissSummarization)
    }

    @Test("Same events are equal") func sameEvents() {
        #expect(ArticleDetailViewEvent.onAppear == .onAppear)
        #expect(ArticleDetailViewEvent.onBookmarkTapped == .onBookmarkTapped)
    }
}
