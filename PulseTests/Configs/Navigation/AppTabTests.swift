import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("AppTab Tests")
struct AppTabTests {
    @Test("all cases have symbolImage")
    func allCasesHaveSymbolImage() {
        let tabs: [AppTab] = [.home, .media, .feed, .bookmarks, .search]
        for tab in tabs {
            let image = tab.symbolImage
            #expect(!image.isEmpty)
        }
    }

    @Test("home tab has newspaper symbol")
    func homeTabHasNewspaperSymbol() {
        #expect(AppTab.home.symbolImage == "newspaper")
    }

    @Test("media tab has play.tv symbol")
    func mediaTabHasPlayTVSymbol() {
        #expect(AppTab.media.symbolImage == "play.tv")
    }

    @Test("feed tab has text.document symbol")
    func feedTabHasTextDocumentSymbol() {
        #expect(AppTab.feed.symbolImage == "text.document")
    }

    @Test("bookmarks tab has bookmark symbol")
    func bookmarksTabHasBookmarkSymbol() {
        #expect(AppTab.bookmarks.symbolImage == "bookmark")
    }

    @Test("search tab has magnifyingglass symbol")
    func searchTabHasMagnifyingGlassSymbol() {
        #expect(AppTab.search.symbolImage == "magnifyingglass")
    }

    @Test("all cases have symbolEffect")
    func allCasesHaveSymbolEffect() {
        let tabs: [AppTab] = [.home, .media, .feed, .bookmarks, .search]
        for tab in tabs {
            _ = tab.symbolEffect
        }
        #expect(tabs.count == AppTab.allCases.count)
    }

    @Test("all cases produce a non-empty localized title")
    func allCasesHaveLocalizedTitle() {
        for tab in AppTab.allCases {
            #expect(!tab.title.isEmpty)
        }
    }

    @Test("titles are distinct per tab")
    func titlesAreDistinct() {
        let titles = AppTab.allCases.map(\.title)
        #expect(Set(titles).count == AppTab.allCases.count)
    }
}
