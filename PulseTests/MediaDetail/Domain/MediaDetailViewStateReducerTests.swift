import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailViewStateReducer Tests")
struct MediaDetailViewStateReducerTests {
    let sut = MediaDetailViewStateReducer()

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

    // MARK: - Basic Mapping Tests

    @Test("Reducer maps article correctly")
    func mapsArticle() {
        let domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article.id == testVideoArticle.id)
        #expect(viewState.article.title == testVideoArticle.title)
    }

    @Test("Reducer maps isPlaying correctly")
    func mapsIsPlaying() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.isPlaying = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isPlaying == true)
    }

    @Test("Reducer maps playbackProgress correctly")
    func mapsPlaybackProgress() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.playbackProgress = 0.75

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.playbackProgress == 0.75)
    }

    @Test("Reducer maps isLoading correctly")
    func mapsIsLoading() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.isLoading = false

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoading == false)
    }

    @Test("Reducer maps error message correctly")
    func mapsErrorMessage() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.error = "Playback failed"

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == "Playback failed")
    }

    @Test("Reducer maps showShareSheet correctly")
    func mapsShowShareSheet() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.showShareSheet = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showShareSheet == true)
    }

    @Test("Reducer maps isBookmarked correctly")
    func mapsIsBookmarked() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.isBookmarked = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isBookmarked == true)
    }

    // MARK: - Time Formatting Tests

    @Test("Formats zero time as 0:00")
    func formatsZeroTime() {
        let domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "0:00")
    }

    @Test("Formats seconds only time")
    func formatsSecondsOnly() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.currentTime = 45

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "0:45")
    }

    @Test("Formats minutes and seconds")
    func formatsMinutesAndSeconds() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.currentTime = 125 // 2:05

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "2:05")
    }

    @Test("Formats hours minutes and seconds")
    func formatsHoursMinutesAndSeconds() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.currentTime = 3665 // 1:01:05

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "1:01:05")
    }

    @Test("Formats duration time")
    func formatsDuration() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.duration = 185 // 3:05

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.durationFormatted == "3:05")
    }

    @Test("Handles negative time by returning 0:00")
    func handlesNegativeTime() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.currentTime = -10

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "0:00")
    }

    @Test("Handles infinite time by returning 0:00")
    func handlesInfiniteTime() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.currentTime = Double.infinity

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.currentTimeFormatted == "0:00")
    }

    // MARK: - Complete State Tests

    @Test("Reduces complete domain state correctly")
    func reducesCompleteState() {
        var domainState = MediaDetailDomainState.initial(article: testVideoArticle)
        domainState.isPlaying = true
        domainState.playbackProgress = 0.5
        domainState.currentTime = 125
        domainState.duration = 300
        domainState.isLoading = false
        domainState.isBookmarked = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.article.id == testVideoArticle.id)
        #expect(viewState.isPlaying == true)
        #expect(viewState.playbackProgress == 0.5)
        #expect(viewState.currentTimeFormatted == "2:05")
        #expect(viewState.durationFormatted == "5:00")
        #expect(viewState.isLoading == false)
        #expect(viewState.isBookmarked == true)
    }
}
