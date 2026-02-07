import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveFeedService Tests")
struct LiveFeedServiceTests {
    @Test("LiveFeedService can be instantiated")
    func canBeInstantiated() {
        let service = LiveFeedService()
        #expect(service is FeedService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveFeedService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelReady returns false when model not loaded")
    func isModelReadyReturnsFalseWhenNotLoaded() {
        let service = LiveFeedService()
        #expect(service.isModelReady == false)
    }

    @Test("generateDigest returns AsyncThrowingStream")
    func generateDigestReturnsStream() throws {
        let service = LiveFeedService()
        let articles: [Article] = try [#require(Article.mockArticles.first)]
        let stream = service.generateDigest(from: articles)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }
}
