import Foundation
@testable import Pulse
import Testing

@Suite("MediaDomainState Tests")
struct MediaDomainStateTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private var testMedia: [Article] {
        [
            Article(
                id: "video-1",
                title: "Video 1",
                source: ArticleSource(id: "source-1", name: "Source 1"),
                url: "https://youtube.com/watch?v=1",
                publishedAt: Self.referenceDate,
                category: .technology,
                mediaType: .video
            ),
            Article(
                id: "podcast-1",
                title: "Podcast 1",
                source: ArticleSource(id: "source-2", name: "Source 2"),
                url: "https://spotify.com/episode/1",
                publishedAt: Self.referenceDate.addingTimeInterval(-3600),
                category: .business,
                mediaType: .podcast
            ),
        ]
    }

    @Test("Initial state has correct default values")
    func initialState() {
        let state = MediaDomainState.initial

        #expect(state.selectedType == nil)
        #expect(state.featuredMedia.isEmpty)
        #expect(state.mediaItems.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.isLoadingMore == false)
        #expect(state.isRefreshing == false)
        #expect(state.error == nil)
        #expect(state.currentPage == 1)
        #expect(state.hasMorePages == true)
        #expect(state.hasLoadedInitialData == false)
        #expect(state.selectedMedia == nil)
        #expect(state.mediaToShare == nil)
        #expect(state.mediaToPlay == nil)
    }

    @Test("Selected type can be set")
    func selectedTypeCanBeSet() {
        var state = MediaDomainState.initial

        state.selectedType = .video
        #expect(state.selectedType == .video)

        state.selectedType = .podcast
        #expect(state.selectedType == .podcast)

        state.selectedType = nil
        #expect(state.selectedType == nil)
    }

    @Test("Featured media can be set")
    func featuredMediaCanBeSet() {
        var state = MediaDomainState.initial
        state.featuredMedia = testMedia

        #expect(state.featuredMedia.count == 2)
    }

    @Test("Media items can be set")
    func mediaItemsCanBeSet() {
        var state = MediaDomainState.initial
        state.mediaItems = testMedia

        #expect(state.mediaItems.count == 2)
    }

    @Test("Selected media can be set")
    func selectedMediaCanBeSet() {
        var state = MediaDomainState.initial
        state.selectedMedia = testMedia[0]

        #expect(state.selectedMedia?.id == "video-1")
    }

    @Test("Media to share can be set")
    func mediaToShareCanBeSet() {
        var state = MediaDomainState.initial
        state.mediaToShare = testMedia[1]

        #expect(state.mediaToShare?.id == "podcast-1")
    }

    @Test("Media to play can be set")
    func mediaToPlayCanBeSet() {
        var state = MediaDomainState.initial
        state.mediaToPlay = testMedia[0]

        #expect(state.mediaToPlay?.id == "video-1")
    }

    @Test("States with same values are equal")
    func statesWithSameValuesAreEqual() {
        var state1 = MediaDomainState.initial
        state1.mediaItems = testMedia
        state1.isLoading = true

        var state2 = MediaDomainState.initial
        state2.mediaItems = testMedia
        state2.isLoading = true

        #expect(state1 == state2)
    }

    @Test("States with different values are not equal")
    func statesWithDifferentValuesAreNotEqual() {
        let state1 = MediaDomainState.initial
        var state2 = MediaDomainState.initial
        state2.selectedType = .video

        #expect(state1 != state2)
    }
}
