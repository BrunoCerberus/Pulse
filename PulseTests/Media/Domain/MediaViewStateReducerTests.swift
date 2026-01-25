import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaViewStateReducer Tests")
struct MediaViewStateReducerTests {
    let sut = MediaViewStateReducer()

    /// Fixed date for consistent testing
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200)

    private func createTestArticle(id: String, mediaType: MediaType) -> Article {
        Article(
            id: id,
            title: "Test \(mediaType.rawValue.capitalized)",
            description: "Test description",
            content: nil,
            author: "Test Author",
            source: ArticleSource(id: "test", name: "Test Source"),
            url: "https://example.com/\(id)",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: nil,
            publishedAt: fixedDate,
            category: .technology,
            mediaType: mediaType,
            mediaURL: "https://example.com/media",
            mediaDuration: 3600,
            mediaMimeType: mediaType == .podcast ? "audio/mpeg" : "video/mp4"
        )
    }

    @Test("Reduces initial state correctly")
    func reducesInitialState() {
        let domainState = MediaDomainState.initial

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedType == nil)
        #expect(viewState.featuredMedia.isEmpty)
        #expect(viewState.mediaItems.isEmpty)
        #expect(!viewState.isLoading)
        #expect(!viewState.isLoadingMore)
        #expect(!viewState.isRefreshing)
        #expect(viewState.errorMessage == nil)
        #expect(viewState.showEmptyState) // Empty when not loading and no media
        #expect(viewState.selectedMedia == nil)
        #expect(viewState.mediaToShare == nil)
        #expect(viewState.mediaToPlay == nil)
    }

    @Test("Reduces loaded state with media items correctly")
    func reducesLoadedState() {
        let featuredArticles = [
            createTestArticle(id: "featured-1", mediaType: .video),
            createTestArticle(id: "featured-2", mediaType: .podcast),
        ]
        let mediaArticles = [
            createTestArticle(id: "media-1", mediaType: .video),
            createTestArticle(id: "media-2", mediaType: .podcast),
            createTestArticle(id: "media-3", mediaType: .video),
        ]

        var domainState = MediaDomainState.initial
        domainState.featuredMedia = featuredArticles
        domainState.mediaItems = mediaArticles
        domainState.hasLoadedInitialData = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.featuredMedia.count == 2)
        #expect(viewState.mediaItems.count == 3)
        #expect(!viewState.showEmptyState)
    }

    @Test("Reduces loading state correctly")
    func reducesLoadingState() {
        var domainState = MediaDomainState.initial
        domainState.isLoading = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoading)
        #expect(!viewState.showEmptyState) // Don't show empty state while loading
    }

    @Test("Reduces refreshing state correctly")
    func reducesRefreshingState() {
        var domainState = MediaDomainState.initial
        domainState.isRefreshing = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isRefreshing)
        #expect(!viewState.showEmptyState) // Don't show empty state while refreshing
    }

    @Test("Reduces loading more state correctly")
    func reducesLoadingMoreState() {
        var domainState = MediaDomainState.initial
        domainState.isLoadingMore = true
        domainState.mediaItems = [createTestArticle(id: "1", mediaType: .video)]

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoadingMore)
    }

    @Test("Reduces error state correctly")
    func reducesErrorState() {
        var domainState = MediaDomainState.initial
        domainState.error = "Network error"

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == "Network error")
    }

    @Test("Shows empty state when no media and not loading")
    func showsEmptyState() {
        var domainState = MediaDomainState.initial
        domainState.isLoading = false
        domainState.isRefreshing = false
        domainState.featuredMedia = []
        domainState.mediaItems = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState)
    }

    @Test("MediaViewItem has correct animation index")
    func mediaViewItemHasAnimationIndex() {
        let articles = [
            createTestArticle(id: "1", mediaType: .video),
            createTestArticle(id: "2", mediaType: .podcast),
            createTestArticle(id: "3", mediaType: .video),
        ]

        var domainState = MediaDomainState.initial
        domainState.mediaItems = articles

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.mediaItems[0].animationIndex == 0)
        #expect(viewState.mediaItems[1].animationIndex == 1)
        #expect(viewState.mediaItems[2].animationIndex == 2)
    }

    @Test("Reduces selected type correctly")
    func reducesSelectedType() {
        var domainState = MediaDomainState.initial
        domainState.selectedType = .video

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedType == .video)
    }

    @Test("Passes through selected media correctly")
    func passesSelectedMedia() {
        let article = createTestArticle(id: "selected", mediaType: .video)
        var domainState = MediaDomainState.initial
        domainState.selectedMedia = article

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedMedia?.id == "selected")
    }

    @Test("Passes through media to share correctly")
    func passesMediaToShare() {
        let article = createTestArticle(id: "share", mediaType: .podcast)
        var domainState = MediaDomainState.initial
        domainState.mediaToShare = article

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.mediaToShare?.id == "share")
    }

    @Test("Passes through media to play correctly")
    func passesMediaToPlay() {
        let article = createTestArticle(id: "play", mediaType: .video)
        var domainState = MediaDomainState.initial
        domainState.mediaToPlay = article

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.mediaToPlay?.id == "play")
    }
}
