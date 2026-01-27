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

    @Test("onShareSheetDismissed event") func onShareSheetDismissed() {
        #expect(ArticleDetailViewEvent.onShareSheetDismissed == .onShareSheetDismissed)
    }

    @Test("onReadFullTapped event") func onReadFullTapped() {
        #expect(ArticleDetailViewEvent.onReadFullTapped == .onReadFullTapped)
    }

    @Test("onSummarizeTapped event") func onSummarizeTapped() {
        #expect(ArticleDetailViewEvent.onSummarizeTapped == .onSummarizeTapped)
    }

    @Test("onSummarizationSheetDismissed event") func onSummarizationSheetDismissed() {
        #expect(ArticleDetailViewEvent.onSummarizationSheetDismissed == .onSummarizationSheetDismissed)
    }

    @Test("Same events are equal") func sameEvents() {
        #expect(ArticleDetailViewEvent.onAppear == .onAppear)
        #expect(ArticleDetailViewEvent.onBookmarkTapped == .onBookmarkTapped)
    }
}
