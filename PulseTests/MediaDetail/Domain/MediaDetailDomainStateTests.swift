import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailDomainState Tests")
struct MediaDetailDomainStateTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testVideoArticle: Article {
        Article(
            id: "video-1",
            title: "Test Video",
            source: ArticleSource(id: "source", name: "Source"),
            url: "https://youtube.com/watch?v=1",
            publishedAt: Self.referenceDate,
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
            publishedAt: Self.referenceDate,
            category: .business,
            mediaType: .podcast
        )
    }

    @Test("Initial state for video has correct values")
    func initialStateVideo() {
        let state = MediaDetailDomainState.initial(article: testVideoArticle)

        #expect(state.article.id == "video-1")
        #expect(state.isPlaying == false)
        #expect(state.playbackProgress == 0)
        #expect(state.currentTime == 0)
        #expect(state.duration == 0)
        #expect(state.isLoading == true)
        #expect(state.error == nil)
        #expect(state.showShareSheet == false)
        #expect(state.isBookmarked == false)
    }

    @Test("Initial state for podcast has correct values")
    func initialStatePodcast() {
        let state = MediaDetailDomainState.initial(article: testPodcastArticle)

        #expect(state.article.id == "podcast-1")
        #expect(state.isPlaying == false)
        #expect(state.isLoading == true)
    }

    @Test("isPlaying can be set")
    func isPlayingCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.isPlaying = true
        #expect(state.isPlaying == true)
    }

    @Test("playbackProgress can be set")
    func playbackProgressCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.playbackProgress = 0.5
        #expect(state.playbackProgress == 0.5)
    }

    @Test("currentTime can be set")
    func currentTimeCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.currentTime = 120.5
        #expect(state.currentTime == 120.5)
    }

    @Test("duration can be set")
    func durationCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.duration = 300.0
        #expect(state.duration == 300.0)
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.isLoading = false
        #expect(state.isLoading == false)
    }

    @Test("Error can be set")
    func errorCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.error = "Playback failed"
        #expect(state.error == "Playback failed")
    }

    @Test("showShareSheet can be set")
    func showShareSheetCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.showShareSheet = true
        #expect(state.showShareSheet == true)
    }

    @Test("isBookmarked can be set")
    func isBookmarkedCanBeSet() {
        var state = MediaDetailDomainState.initial(article: testVideoArticle)
        state.isBookmarked = true
        #expect(state.isBookmarked == true)
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = MediaDetailDomainState.initial(article: testVideoArticle)
        let state2 = MediaDetailDomainState.initial(article: testVideoArticle)

        #expect(state1 == state2)
    }

    @Test("States with different isPlaying are not equal")
    func differentIsPlaying() {
        let state1 = MediaDetailDomainState.initial(article: testVideoArticle)
        var state2 = MediaDetailDomainState.initial(article: testVideoArticle)
        state2.isPlaying = true

        #expect(state1 != state2)
    }

    @Test("States with different playbackProgress are not equal")
    func differentPlaybackProgress() {
        let state1 = MediaDetailDomainState.initial(article: testVideoArticle)
        var state2 = MediaDetailDomainState.initial(article: testVideoArticle)
        state2.playbackProgress = 0.5

        #expect(state1 != state2)
    }

    @Test("States with different articles are not equal")
    func differentArticles() {
        let state1 = MediaDetailDomainState.initial(article: testVideoArticle)
        let state2 = MediaDetailDomainState.initial(article: testPodcastArticle)

        #expect(state1 != state2)
    }
}
