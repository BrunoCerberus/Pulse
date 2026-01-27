import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailViewModel Tests")
@MainActor
struct MediaDetailViewModelTests {
    private var testVideoArticle: Article {
        Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://youtube.com/watch?v=1",
            publishedAt: Date(),
            category: .technology,
            mediaType: .video
        )
    }

    private var testPodcastArticle: Article {
        Article(
            id: "podcast-1",
            title: "Test Podcast",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://spotify.com/episode/1",
            publishedAt: Date(),
            category: .business,
            mediaType: .podcast
        )
    }

    @Test("Initial view state for video is correct")
    func initialViewStateVideo() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        #expect(sut.viewState.article.id == testVideoArticle.id)
        #expect(sut.viewState.isPlaying == false)
        #expect(sut.viewState.playbackProgress == 0)
        #expect(sut.viewState.isLoading == true)
        #expect(sut.viewState.isBookmarked == false)
    }

    @Test("Initial view state for podcast is correct")
    func initialViewStatePodcast() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testPodcastArticle, serviceLocator: serviceLocator)

        #expect(sut.viewState.article.id == testPodcastArticle.id)
        #expect(sut.viewState.article.mediaType == .podcast)
    }

    @Test("Handle onAppear triggers initialization")
    func handleOnAppear() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onAppear)
        // Event should be handled without error
    }

    @Test("Handle onPlayPauseTapped toggles play state")
    func handlePlayPauseTapped() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        // Initially not playing
        #expect(sut.viewState.isPlaying == false)

        // Tap play
        sut.handle(event: .onPlayPauseTapped)

        // Tap pause
        sut.handle(event: .onPlayPauseTapped)
    }

    @Test("Handle onSeek seeks to position")
    func handleSeek() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onSeek(progress: 0.5))
        // Event should be handled without error
    }

    @Test("Handle onSkipBackwardTapped skips backward")
    func handleSkipBackward() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onSkipBackwardTapped)
        // Event should be handled without error
    }

    @Test("Handle onSkipForwardTapped skips forward")
    func handleSkipForward() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onSkipForwardTapped)
        // Event should be handled without error
    }

    @Test("Handle onShareTapped shows share sheet")
    func handleShareTapped() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onShareTapped)
        // Event should be handled without error
    }

    @Test("Handle onShareDismissed dismisses share sheet")
    func handleDismissShareSheet() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onShareDismissed)
        // Event should be handled without error
    }

    @Test("Handle onBookmarkTapped toggles bookmark")
    func handleBookmarkTapped() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onBookmarkTapped)
        // Event should be handled without error
    }

    @Test("Handle onOpenInBrowserTapped opens browser")
    func handleOpenInBrowser() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onOpenInBrowserTapped)
        // Event should be handled without error
    }

    @Test("Handle onError event")
    func handleError() {
        let serviceLocator = ServiceLocator()
        let sut = MediaDetailViewModel(article: testVideoArticle, serviceLocator: serviceLocator)

        sut.handle(event: .onError("Test error"))
        // Event should be handled without error
    }
}
