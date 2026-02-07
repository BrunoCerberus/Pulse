import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveMediaService Tests")
struct LiveMediaServiceTests {
    @Test("LiveMediaService can be instantiated")
    func canBeInstantiated() {
        let service = LiveMediaService()
        #expect(service is MediaService)
    }

    @Test("fetchMedia returns correct publisher type")
    func fetchMediaReturnsCorrectType() {
        let service = LiveMediaService()
        let publisher = service.fetchMedia(type: .video, page: 1)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("fetchFeaturedMedia returns correct publisher type")
    func fetchFeaturedMediaReturnsCorrectType() {
        let service = LiveMediaService()
        let publisher = service.fetchFeaturedMedia(type: .podcast)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }
}
