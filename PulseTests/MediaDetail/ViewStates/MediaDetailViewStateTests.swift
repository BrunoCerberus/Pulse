import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailViewState Tests")
struct MediaDetailViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let article = Article.mockArticles[0]
        let state = MediaDetailViewState.initial(article: article)

        #expect(state.article == article)
        #expect(!state.isPlaying)
        #expect(state.playbackProgress == 0)
        #expect(state.currentTimeFormatted == "0:00")
        #expect(state.isLoading)
        #expect(state.errorMessage == nil)
        #expect(!state.showShareSheet)
        #expect(!state.isBookmarked)
    }

    @Test("Initial state uses article formatted duration")
    func usesArticleFormattedDuration() {
        let article = Article.mockArticles[0]
        let state = MediaDetailViewState.initial(article: article)

        #expect(state.durationFormatted == (article.formattedDuration ?? "0:00"))
    }

    @Test("MediaDetailViewState is Equatable")
    func equatable() {
        let article = Article.mockArticles[0]
        let state1 = MediaDetailViewState.initial(article: article)
        let state2 = MediaDetailViewState.initial(article: article)

        #expect(state1 == state2)
    }

    @Test("Different articles produce different states")
    func differentArticles() {
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        let state1 = MediaDetailViewState.initial(article: article1)
        let state2 = MediaDetailViewState.initial(article: article2)

        #expect(state1 != state2)
    }

    @Test("Modified playback state is not equal to initial")
    func modifiedPlaybackState() {
        let article = Article.mockArticles[0]
        var state = MediaDetailViewState.initial(article: article)
        let initial = MediaDetailViewState.initial(article: article)

        state.isPlaying = true
        #expect(state != initial)
    }

    @Test("Modified progress state is not equal to initial")
    func modifiedProgressState() {
        let article = Article.mockArticles[0]
        var state = MediaDetailViewState.initial(article: article)
        let initial = MediaDetailViewState.initial(article: article)

        state.playbackProgress = 0.5
        state.currentTimeFormatted = "2:30"
        #expect(state != initial)
    }
}
