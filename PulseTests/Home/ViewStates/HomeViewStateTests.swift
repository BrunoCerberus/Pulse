import Foundation
@testable import Pulse
import Testing

// MARK: - HomeViewState Tests

@Suite("HomeViewState Tests")
struct HomeViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = HomeViewState.initial

        #expect(state.breakingNews.isEmpty)
        #expect(state.headlines.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(state.selectedArticle == nil)
        #expect(state.articleToShare == nil)
        #expect(state.selectedCategory == nil)
        #expect(state.followedTopics.isEmpty)
        #expect(!state.showCategoryTabs)
        #expect(state.allTopics == NewsCategory.allCases)
        #expect(!state.isEditingTopics)
    }

    @Test("HomeViewState is Equatable")
    func equatable() {
        let state1 = HomeViewState.initial
        let state2 = HomeViewState.initial

        #expect(state1 == state2)
    }

    @Test("HomeViewState with different values are not equal")
    func notEqual() {
        var state1 = HomeViewState.initial
        var state2 = HomeViewState.initial

        state1.isLoading = true
        #expect(state1 != state2)

        state2.isLoading = true
        state1.selectedCategory = .technology
        #expect(state1 != state2)
    }
}

// MARK: - ArticleViewItem Tests

@Suite("ArticleViewItem Tests")
struct ArticleViewItemTests {
    @Test("ArticleViewItem initializes from Article")
    func initFromArticle() {
        let article = Article.mockArticles[0]
        let viewItem = ArticleViewItem(from: article, index: 5)

        #expect(viewItem.id == article.id)
        #expect(viewItem.title == article.title)
        #expect(viewItem.description == article.description)
        #expect(viewItem.sourceName == article.source.name)
        #expect(viewItem.formattedDate == article.formattedDate)
        #expect(viewItem.category == article.category)
        #expect(viewItem.animationIndex == 5)
    }

    @Test("ArticleViewItem default index is 0")
    func defaultIndex() {
        let article = Article.mockArticles[0]
        let viewItem = ArticleViewItem(from: article)

        #expect(viewItem.animationIndex == 0)
    }

    @Test("ArticleViewItem creates image URL from string")
    func createsImageURL() {
        let article = Article(
            title: "Test",
            description: nil,
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Date()
        )
        let viewItem = ArticleViewItem(from: article)

        #expect(viewItem.imageURL != nil)
        #expect(viewItem.imageURL?.absoluteString.contains("image.jpg") == true)
    }

    @Test("ArticleViewItem handles nil image URL")
    func handlesNilImageURL() {
        let article = Article(
            title: "Test",
            description: nil,
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )
        let viewItem = ArticleViewItem(from: article)

        #expect(viewItem.imageURL == nil)
        #expect(viewItem.heroImageURL == nil)
    }

    @Test("ArticleViewItem is Identifiable")
    func identifiable() {
        let article = Article.mockArticles[0]
        let viewItem = ArticleViewItem(from: article)

        #expect(viewItem.id == article.id)
    }

    @Test("ArticleViewItem is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let item1 = ArticleViewItem(from: article, index: 0)
        let item2 = ArticleViewItem(from: article, index: 0)

        #expect(item1 == item2)
    }

    @Test("ArticleViewItems with different indices are not equal")
    func differentIndicesNotEqual() {
        let article = Article.mockArticles[0]
        let item1 = ArticleViewItem(from: article, index: 0)
        let item2 = ArticleViewItem(from: article, index: 1)

        #expect(item1 != item2)
    }

    @Test("ArticleViewItem maps multiple articles correctly")
    func mapsMultipleArticles() {
        let articles = Article.mockArticles
        let viewItems = articles.enumerated().map { index, article in
            ArticleViewItem(from: article, index: index)
        }

        #expect(viewItems.count == articles.count)
        for (index, viewItem) in viewItems.enumerated() {
            #expect(viewItem.animationIndex == index)
            #expect(viewItem.id == articles[index].id)
        }
    }
}
