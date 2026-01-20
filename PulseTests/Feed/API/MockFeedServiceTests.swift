import Foundation
@testable import Pulse
import Testing

@Suite("MockFeedService Tests")
struct MockFeedServiceTests {
    var sut: MockFeedService

    init() {
        sut = MockFeedService()
    }

    @Test("Initial state is not loaded")
    func initialStateNotLoaded() {
        #expect(!sut.isModelReady)
    }

    @Test("Model status publisher emits initial state")
    func modelStatusPublisherEmitsInitial() {
        var receivedStatuses: [LLMModelStatus] = []
        let cancellable = sut.modelStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }

        #expect(!receivedStatuses.isEmpty)
        #expect(receivedStatuses.first == .notLoaded)

        cancellable.cancel()
    }

    @Test("Load modelIfNeeded success")
    func loadModelIfNeededSuccess() async throws {
        sut.shouldFail = false

        try await sut.loadModelIfNeeded()

        #expect(sut.isModelReady)
    }

    @Test("Load modelIfNeeded failure")
    func loadModelIfNeededFailure() async throws {
        sut.shouldFail = true

        do {
            try await sut.loadModelIfNeeded()
            Issue.record("Expected error was thrown")
        } catch {}

        #expect(!sut.isModelReady)
    }

    @Test("Load modelIfNeeded skips if already loaded")
    func loadModelIfNeededSkipsIfAlreadyLoaded() async throws {
        sut.shouldFail = false
        try await sut.loadModelIfNeeded()
        #expect(sut.isModelReady)

        try await sut.loadModelIfNeeded()

        #expect(sut.isModelReady)
    }

    @Test("Simulate model status updates")
    func simulateModelStatusUpdates() {
        let statuses: [LLMModelStatus] = [
            .notLoaded,
            .loading(progress: 0.5),
            .loading(progress: 1.0),
            .ready,
        ]

        for status in statuses {
            sut.simulateModelStatus(status)
        }

        #expect(sut.isModelReady)
    }

    @Test("Fetch todays digest returns mock digest")
    func fetchTodaysDigestReturnsMock() {
        let mockDigest = DailyDigest(
            id: "test-digest",
            summary: "Test summary",
            sourceArticles: [],
            generatedAt: Date()
        )
        sut.mockDigest = mockDigest

        let digest = sut.fetchTodaysDigest()

        #expect(digest?.id == "test-digest")
    }

    @Test("Fetch todays digest returns nil when not set")
    func fetchTodaysDigestReturnsNil() {
        sut.mockDigest = nil

        let digest = sut.fetchTodaysDigest()

        #expect(digest == nil)
    }

    @Test("Generate digest stream yields tokens")
    func generateDigestStreamYieldsTokens() async {
        let articles = Array(Article.mockArticles.prefix(3))

        var receivedTokens: [String] = []
        let stream = sut.generateDigest(from: articles)

        do {
            for try await token in stream {
                receivedTokens.append(token)
            }
        } catch {}

        #expect(!receivedTokens.isEmpty)
    }

    @Test("Generate digest with shouldFail")
    func generateDigestWithShouldFail() async {
        sut.shouldFail = true
        let articles = Array(Article.mockArticles.prefix(1))

        var receivedError: Error?
        let stream = sut.generateDigest(from: articles)

        do {
            for try await _ in stream {}
        } catch {
            receivedError = error
        }

        #expect(receivedError != nil)
    }

    @Test("Generate digest with custom stream tokens")
    func generateDigestWithCustomTokens() async {
        sut.streamTokens = ["Hello", " ", "World"]
        let articles = Array(Article.mockArticles.prefix(1))

        var receivedTokens: [String] = []
        let stream = sut.generateDigest(from: articles)

        do {
            for try await token in stream {
                receivedTokens.append(token)
            }
        } catch {}

        #expect(receivedTokens.count == 3)
    }

    @Test("Save digest updates mock digest")
    func saveDigestUpdatesMock() {
        let mockDigest = DailyDigest(
            id: "saved-digest",
            summary: "Saved summary",
            sourceArticles: [],
            generatedAt: Date()
        )

        sut.saveDigest(mockDigest)

        #expect(sut.mockDigest?.id == "saved-digest")
    }

    @Test("With sample data returns pre-configured service")
    func withSampleDataReturnsPreconfigured() {
        let service = MockFeedService.withSampleData()

        let digest = service.fetchTodaysDigest()

        #expect(digest != nil)
        #expect(!digest!.sourceArticles.isEmpty)
    }
}
