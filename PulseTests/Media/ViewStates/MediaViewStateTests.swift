import Foundation
@testable import Pulse
import Testing

// MARK: - MediaViewState Tests

@Suite("MediaViewState Tests")
struct MediaViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = MediaViewState.initial

        #expect(state.selectedType == nil)
        #expect(state.featuredMedia.isEmpty)
        #expect(state.mediaItems.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isLoadingMore)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(!state.showEmptyState)
        #expect(state.selectedMedia == nil)
        #expect(state.mediaToShare == nil)
        #expect(state.mediaToPlay == nil)
    }

    @Test("MediaViewState is Equatable")
    func equatable() {
        let state1 = MediaViewState.initial
        let state2 = MediaViewState.initial

        #expect(state1 == state2)
    }

    @Test("MediaViewState with different values are not equal")
    func notEqual() {
        var state1 = MediaViewState.initial
        var state2 = MediaViewState.initial

        state1.isLoading = true
        state2.isLoading = false

        #expect(state1 != state2)
    }
}

// MARK: - MediaViewItem Tests

@Suite("MediaViewItem Tests")
struct MediaViewItemTests {
    @Test("MediaViewItem initializes from Article")
    func initFromArticle() {
        let article = Article.mockArticles[0]
        let viewItem = MediaViewItem(from: article, index: 3)

        #expect(viewItem.id == article.id)
        #expect(viewItem.title == article.title)
        #expect(viewItem.description == article.description)
        #expect(viewItem.sourceName == article.source.name)
        #expect(viewItem.formattedDate == article.formattedDate)
        #expect(viewItem.animationIndex == 3)
        #expect(viewItem.url == article.url)
    }

    @Test("MediaViewItem default index is 0")
    func defaultIndex() {
        let article = Article.mockArticles[0]
        let viewItem = MediaViewItem(from: article)

        #expect(viewItem.animationIndex == 0)
    }

    @Test("MediaViewItem maps media fields")
    func mapsMediaFields() {
        let article = Article.mockArticles[0]
        let viewItem = MediaViewItem(from: article)

        #expect(viewItem.formattedDuration == article.formattedDuration)
        #expect(viewItem.mediaType == article.mediaType)
        #expect(viewItem.mediaURL == article.mediaURL)
    }

    @Test("MediaViewItem creates image URLs correctly")
    func createsImageURLs() {
        let article = Article(
            title: "Test",
            description: nil,
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            publishedAt: Date()
        )
        let viewItem = MediaViewItem(from: article)

        #expect(viewItem.imageURL != nil)
    }

    @Test("MediaViewItem handles nil image URL")
    func handlesNilImageURL() {
        let article = Article(
            title: "Test",
            description: nil,
            source: ArticleSource(id: nil, name: "Test"),
            url: "https://example.com",
            publishedAt: Date()
        )
        let viewItem = MediaViewItem(from: article)

        #expect(viewItem.imageURL == nil)
        #expect(viewItem.heroImageURL == nil)
    }

    @Test("MediaViewItem is Identifiable")
    func identifiable() {
        let article = Article.mockArticles[0]
        let viewItem = MediaViewItem(from: article)

        #expect(viewItem.id == article.id)
    }

    @Test("MediaViewItem is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let item1 = MediaViewItem(from: article, index: 0)
        let item2 = MediaViewItem(from: article, index: 0)

        #expect(item1 == item2)
    }

    @Test("MediaViewItems with different indices are not equal")
    func differentIndicesNotEqual() {
        let article = Article.mockArticles[0]
        let item1 = MediaViewItem(from: article, index: 0)
        let item2 = MediaViewItem(from: article, index: 1)

        #expect(item1 != item2)
    }
}
