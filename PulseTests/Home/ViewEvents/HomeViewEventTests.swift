import Foundation
@testable import Pulse
import Testing

@Suite("HomeViewEvent Tests")
struct HomeViewEventTests {
    @Test("onAppear event exists") func onAppear() {
        #expect(HomeViewEvent.onAppear == .onAppear)
    }

    @Test("onRefresh event exists") func onRefresh() {
        #expect(HomeViewEvent.onRefresh == .onRefresh)
    }

    @Test("onLoadMore event exists") func onLoadMore() {
        #expect(HomeViewEvent.onLoadMore == .onLoadMore)
    }

    @Test("onArticleTapped event") func onArticleTapped() {
        let event = HomeViewEvent.onArticleTapped(articleId: "id")
        if case let .onArticleTapped(id) = event { #expect(id == "id") }
    }

    @Test("onBookmarkTapped event") func onBookmarkTapped() {
        let event = HomeViewEvent.onBookmarkTapped(articleId: "id")
        if case let .onBookmarkTapped(id) = event { #expect(id == "id") }
    }

    @Test("onShareTapped event") func onShareTapped() {
        let event = HomeViewEvent.onShareTapped(articleId: "id")
        if case let .onShareTapped(id) = event { #expect(id == "id") }
    }

    @Test("onShareDismissed event") func onShareDismissed() {
        #expect(HomeViewEvent.onShareDismissed == .onShareDismissed)
    }

    @Test("onCategorySelected event") func onCategorySelected() {
        let event = HomeViewEvent.onCategorySelected(.technology)
        if case let .onCategorySelected(cat) = event { #expect(cat == .technology) }
    }
}
