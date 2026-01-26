import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("MediaDetailDomainInteractor Tests")
@MainActor
struct MediaDetailDomainInteractorTests {
    let mockStorageService: MockStorageService
    let serviceLocator: ServiceLocator
    let testArticle: Article
    let sut: MediaDetailDomainInteractor

    init() {
        mockStorageService = MockStorageService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StorageService.self, instance: mockStorageService)

        testArticle = Article(
            id: "test-video-1",
            title: "Test Video Title",
            description: "Test video description",
            content: nil,
            author: "Test Author",
            source: ArticleSource(id: "youtube", name: "YouTube"),
            url: "https://www.youtube.com/watch?v=test123",
            imageURL: "https://img.youtube.com/vi/test123/maxresdefault.jpg",
            thumbnailURL: nil,
            publishedAt: Date(),
            category: .technology,
            mediaType: .video,
            mediaURL: "https://www.youtube.com/watch?v=test123",
            mediaDuration: 600,
            mediaMimeType: "video/youtube"
        )

        sut = MediaDetailDomainInteractor(article: testArticle, serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.article.id == testArticle.id)
        #expect(!state.isPlaying)
        #expect(state.playbackProgress == 0)
        #expect(state.currentTime == 0)
        #expect(state.duration == 0)
        #expect(state.isLoading)
        #expect(state.error == nil)
        #expect(!state.showShareSheet)
        #expect(!state.isBookmarked)
    }

    // MARK: - Lifecycle Tests

    @Test("onAppear checks bookmark status")
    func testOnAppear() async throws {
        // Pre-bookmark the article
        try await mockStorageService.saveArticle(testArticle)

        sut.dispatch(action: .onAppear)

        // Poll for state change with timeout
        var attempts = 0
        let maxAttempts = 20
        while !sut.currentState.isBookmarked, attempts < maxAttempts {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }

        #expect(sut.currentState.isBookmarked, "Bookmark status should be loaded after onAppear")
    }

    // MARK: - Playback Control Tests

    @Test("Play action sets isPlaying to true")
    func testPlay() {
        sut.dispatch(action: .play)
        #expect(sut.currentState.isPlaying)
    }

    @Test("Pause action sets isPlaying to false")
    func testPause() {
        sut.dispatch(action: .play)
        #expect(sut.currentState.isPlaying)

        sut.dispatch(action: .pause)
        #expect(!sut.currentState.isPlaying)
    }

    @Test("Seek action updates progress and currentTime")
    func testSeek() {
        // First set duration so seek can calculate time
        sut.dispatch(action: .durationLoaded(600))

        sut.dispatch(action: .seek(to: 0.5))

        let state = sut.currentState
        #expect(state.playbackProgress == 0.5)
        #expect(state.currentTime == 300) // 50% of 600 seconds
    }

    @Test("Skip backward adjusts time correctly")
    func testSkipBackward() {
        sut.dispatch(action: .durationLoaded(600))
        sut.dispatch(action: .playbackProgressUpdated(progress: 0.5, currentTime: 300))

        sut.dispatch(action: .skipBackward(seconds: 15))

        let state = sut.currentState
        #expect(state.currentTime == 285) // 300 - 15
    }

    @Test("Skip backward doesn't go below zero")
    func skipBackwardAtStart() {
        sut.dispatch(action: .durationLoaded(600))
        sut.dispatch(action: .playbackProgressUpdated(progress: 0.01, currentTime: 5))

        sut.dispatch(action: .skipBackward(seconds: 15))

        let state = sut.currentState
        #expect(state.currentTime == 0)
    }

    @Test("Skip forward adjusts time correctly")
    func testSkipForward() {
        sut.dispatch(action: .durationLoaded(600))
        sut.dispatch(action: .playbackProgressUpdated(progress: 0.5, currentTime: 300))

        sut.dispatch(action: .skipForward(seconds: 30))

        let state = sut.currentState
        #expect(state.currentTime == 330) // 300 + 30
    }

    @Test("Skip forward doesn't exceed duration")
    func skipForwardAtEnd() {
        sut.dispatch(action: .durationLoaded(600))
        sut.dispatch(action: .playbackProgressUpdated(progress: 0.98, currentTime: 590))

        sut.dispatch(action: .skipForward(seconds: 30))

        let state = sut.currentState
        #expect(state.currentTime == 600) // Capped at duration
    }

    // MARK: - Playback Events Tests

    @Test("Playback progress updates state")
    func testPlaybackProgressUpdated() {
        sut.dispatch(action: .playbackProgressUpdated(progress: 0.25, currentTime: 150))

        let state = sut.currentState
        #expect(state.playbackProgress == 0.25)
        #expect(state.currentTime == 150)
    }

    @Test("Duration loaded updates state and clears loading")
    func testDurationLoaded() {
        #expect(sut.currentState.isLoading)

        sut.dispatch(action: .durationLoaded(3600))

        let state = sut.currentState
        #expect(state.duration == 3600)
        #expect(!state.isLoading)
    }

    @Test("Player loading sets isLoading")
    func testPlayerLoading() {
        sut.dispatch(action: .playerReady)
        #expect(!sut.currentState.isLoading)

        sut.dispatch(action: .playerLoading)
        #expect(sut.currentState.isLoading)
    }

    @Test("Player ready clears isLoading")
    func testPlayerReady() {
        sut.dispatch(action: .playerReady)
        #expect(!sut.currentState.isLoading)
    }

    @Test("Playback error updates state")
    func testPlaybackError() {
        sut.dispatch(action: .play)

        sut.dispatch(action: .playbackError("Video unavailable"))

        let state = sut.currentState
        #expect(state.error == "Video unavailable")
        #expect(!state.isLoading)
        #expect(!state.isPlaying)
    }

    // MARK: - Share Sheet Tests

    @Test("Show share sheet sets state")
    func testShowShareSheet() {
        sut.dispatch(action: .showShareSheet)
        #expect(sut.currentState.showShareSheet)
    }

    @Test("Dismiss share sheet clears state")
    func testDismissShareSheet() {
        sut.dispatch(action: .showShareSheet)
        #expect(sut.currentState.showShareSheet)

        sut.dispatch(action: .dismissShareSheet)
        #expect(!sut.currentState.showShareSheet)
    }

    // MARK: - Bookmark Tests

    @Test("Toggle bookmark adds bookmark when not bookmarked")
    func toggleBookmarkAdd() async throws {
        #expect(!sut.currentState.isBookmarked)

        sut.dispatch(action: .toggleBookmark)

        // Optimistic update
        #expect(sut.currentState.isBookmarked)

        // Wait for background task
        try await Task.sleep(nanoseconds: 200_000_000)

        // Verify persisted
        let isBookmarked = await mockStorageService.isBookmarked(testArticle.id)
        #expect(isBookmarked)
    }

    @Test("Toggle bookmark removes bookmark when bookmarked")
    func toggleBookmarkRemove() async throws {
        // Pre-bookmark
        try await mockStorageService.saveArticle(testArticle)
        sut.dispatch(action: .bookmarkStatusLoaded(true))
        #expect(sut.currentState.isBookmarked)

        sut.dispatch(action: .toggleBookmark)

        // Optimistic update
        #expect(!sut.currentState.isBookmarked)

        // Wait for background task
        try await Task.sleep(nanoseconds: 200_000_000)

        // Verify removed
        let isBookmarked = await mockStorageService.isBookmarked(testArticle.id)
        #expect(!isBookmarked)
    }

    @Test("Bookmark status loaded updates state")
    func testBookmarkStatusLoaded() {
        sut.dispatch(action: .bookmarkStatusLoaded(true))
        #expect(sut.currentState.isBookmarked)

        sut.dispatch(action: .bookmarkStatusLoaded(false))
        #expect(!sut.currentState.isBookmarked)
    }
}
