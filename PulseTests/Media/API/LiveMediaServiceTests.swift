import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveMediaService Tests")
struct LiveMediaServiceTests {
    // MARK: - Instantiation Tests

    @Test("LiveMediaService can be instantiated")
    func canBeInstantiated() {
        let service = LiveMediaService()
        let isMediaService = service is MediaService

        #expect(isMediaService == true)
    }

    // MARK: - Protocol Conformance Tests

    @Test("fetchMedia returns correct publisher type")
    func fetchMediaReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchMedia(type: nil, language: "en", page: 1)

        // Verify the publisher has the expected type signature
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    @Test("fetchMedia with video type returns correct publisher type")
    func fetchMediaWithVideoTypeReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchMedia(type: .video, language: "en", page: 1)

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    @Test("fetchMedia with podcast type returns correct publisher type")
    func fetchMediaWithPodcastTypeReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchMedia(type: .podcast, language: "en", page: 1)

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    @Test("fetchFeaturedMedia returns correct publisher type")
    func fetchFeaturedMediaReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchFeaturedMedia(type: nil, language: "en")

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    @Test("fetchFeaturedMedia with video type returns correct publisher type")
    func fetchFeaturedMediaWithVideoTypeReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchFeaturedMedia(type: .video, language: "en")

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    @Test("fetchFeaturedMedia with podcast type returns correct publisher type")
    func fetchFeaturedMediaWithPodcastTypeReturnsCorrectType() {
        let service = LiveMediaService()

        let publisher = service.fetchFeaturedMedia(type: .podcast, language: "en")

        let typeCheck: AnyPublisher<[Article], Error> = publisher
        let isCorrectType = typeCheck is AnyPublisher<[Article], Error>
        #expect(isCorrectType == true)
    }

    // MARK: - Pagination Tests

    @Test("fetchMedia accepts different page numbers")
    func fetchMediaAcceptsDifferentPageNumbers() {
        let service = LiveMediaService()

        // Should not throw for various page numbers
        let page1Publisher = service.fetchMedia(type: nil, language: "en", page: 1)
        let page2Publisher = service.fetchMedia(type: nil, language: "en", page: 2)
        let page10Publisher = service.fetchMedia(type: nil, language: "en", page: 10)

        let isPage1Type = page1Publisher is AnyPublisher<[Article], Error>
        let isPage2Type = page2Publisher is AnyPublisher<[Article], Error>
        let isPage10Type = page10Publisher is AnyPublisher<[Article], Error>

        #expect(isPage1Type == true)
        #expect(isPage2Type == true)
        #expect(isPage10Type == true)
    }
}

@Suite("MockMediaService Tests")
struct MockMediaServiceTests {
    // MARK: - Basic Functionality Tests

    @Test("MockMediaService returns sample media")
    func returnsBasicMedia() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0 // No delay for tests

        var result: [Article] = []
        var cancellables = Set<AnyCancellable>()

        mockService.fetchMedia(type: nil, language: "en", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    result = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!result.isEmpty)
    }

    @Test("MockMediaService filters by video type")
    func filtersByVideoType() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0

        var result: [Article] = []
        var cancellables = Set<AnyCancellable>()

        mockService.fetchMedia(type: .video, language: "en", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    result = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.allSatisfy { $0.mediaType == .video })
    }

    @Test("MockMediaService filters by podcast type")
    func filtersByPodcastType() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0

        var result: [Article] = []
        var cancellables = Set<AnyCancellable>()

        mockService.fetchMedia(type: .podcast, language: "en", page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    result = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.allSatisfy { $0.mediaType == .podcast })
    }

    @Test("MockMediaService returns featured media")
    func returnsFeaturedMedia() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0

        var result: [Article] = []
        var cancellables = Set<AnyCancellable>()

        mockService.fetchFeaturedMedia(type: nil, language: "en")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    result = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!result.isEmpty)
        #expect(result.count <= 5) // Featured limited to 5
    }

    @Test("MockMediaService can simulate failure")
    func canSimulateFailure() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0
        mockService.shouldFail = true

        var receivedError: Error?
        var cancellables = Set<AnyCancellable>()

        mockService.fetchMedia(type: nil, language: "en", page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedError != nil)
        let isURLError = receivedError is URLError
        #expect(isURLError == true)
    }

    @Test("MockMediaService returns empty for page beyond data")
    func returnsEmptyForPageBeyondData() async throws {
        let mockService = MockMediaService()
        mockService.simulatedDelay = 0

        var result: [Article] = []
        var cancellables = Set<AnyCancellable>()

        mockService.fetchMedia(type: nil, language: "en", page: 100)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { articles in
                    result = articles
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.isEmpty)
    }

    // MARK: - Sample Data Tests

    @Test("Sample media contains both videos and podcasts")
    func sampleMediaContainsBothTypes() {
        let sampleMedia = MockMediaService.sampleMedia

        let hasVideos = sampleMedia.contains { $0.mediaType == .video }
        let hasPodcasts = sampleMedia.contains { $0.mediaType == .podcast }

        #expect(hasVideos)
        #expect(hasPodcasts)
    }

    @Test("Sample media articles have required properties")
    func sampleMediaHasRequiredProperties() {
        for article in MockMediaService.sampleMedia {
            #expect(!article.id.isEmpty)
            #expect(!article.title.isEmpty)
            #expect(article.url != nil)
            #expect(article.mediaType != nil)
            #expect(article.mediaURL != nil)
        }
    }

    @Test("Sample videos have video media type")
    func sampleVideosHaveCorrectMediaType() {
        let videos = MockMediaService.sampleMedia.filter { $0.id.hasPrefix("video-") }

        for video in videos {
            #expect(video.mediaType == .video)
        }
    }

    @Test("Sample podcasts have podcast media type")
    func samplePodcastsHaveCorrectMediaType() {
        let podcasts = MockMediaService.sampleMedia.filter { $0.id.hasPrefix("podcast-") }

        for podcast in podcasts {
            #expect(podcast.mediaType == .podcast)
        }
    }
}
