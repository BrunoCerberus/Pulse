import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("Page Tests")
struct PageTests {
    @Test("all cases are hashable")
    func allCasesAreHashable() throws {
        let article = try #require(Article.mockArticles.first)
        let page1: Page = .articleDetail(article)
        let page2: Page = .articleDetail(article)
        let page3: Page = .settings

        var set = Set<Page>()
        set.insert(page1)
        set.insert(page2)
        set.insert(page3)

        #expect(set.count == 2)
    }

    @Test("articleDetail case stores article")
    func articleDetailCaseStoresArticle() throws {
        let article = try #require(Article.mockArticles.first)
        let page: Page = .articleDetail(article)

        if case let .articleDetail(storedArticle) = page {
            #expect(storedArticle.id == article.id)
        } else {
            Issue.record("Expected articleDetail case")
        }
    }

    @Test("settings case is value")
    func settingsCaseIsValue() {
        let page: Page = .settings

        if case .settings = page {
            // Success
        } else {
            Issue.record("Expected settings case")
        }
    }
}
