import Combine
import Foundation

final class MockFeedService: FeedService {
    // MARK: - Configuration

    var shouldFail = false
    var loadDelay: TimeInterval = 0.5
    var generateDelay: TimeInterval = 0.05
    var mockDigest: DailyDigest?
    var mockModelStatus: LLMModelStatus = .notLoaded

    // MARK: - Call Tracking

    private(set) var loadModelCallCount = 0

    /// Alias for mockDigest for cleaner test code
    var cachedDigest: DailyDigest? {
        get { mockDigest }
        set { mockDigest = newValue }
    }

    /// Custom tokens to stream during generation (if set, overrides default summary)
    var streamTokens: [String]?

    private let modelStatusSubject = CurrentValueSubject<LLMModelStatus, Never>(.notLoaded)

    /// Simulate a model status change for testing
    func simulateModelStatus(_ status: LLMModelStatus) {
        modelStatusSubject.send(status)
    }

    // MARK: - FeedService Protocol

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        modelStatusSubject.eraseToAnyPublisher()
    }

    var isModelReady: Bool {
        modelStatusSubject.value == .ready
    }

    func loadModelIfNeeded() async throws {
        loadModelCallCount += 1
        guard !isModelReady else { return }

        if shouldFail {
            modelStatusSubject.send(.error("Mock error: Model load failed"))
            throw FeedServiceError.modelNotReady
        }

        // Simulate loading progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.2) {
            modelStatusSubject.send(.loading(progress: progress))
            try await Task.sleep(for: .milliseconds(Int(loadDelay * 200)))
        }

        modelStatusSubject.send(.ready)
    }

    func fetchTodaysDigest() -> DailyDigest? {
        mockDigest
    }

    func generateDigest(from articles: [Article]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if self.shouldFail {
                    continuation.finish(throwing: FeedServiceError.generationFailed("Mock generation failed"))
                    return
                }

                // Use custom tokens if set, otherwise generate from articles
                let tokens: [String]
                if let customTokens = self.streamTokens {
                    tokens = customTokens
                } else {
                    let mockSummary = Self.generateMockSummary(for: articles)
                    tokens = mockSummary.split(separator: " ").map { String($0) + " " }
                }

                for token in tokens {
                    try await Task.sleep(for: .milliseconds(Int(self.generateDelay * 1000)))
                    continuation.yield(token)
                }

                continuation.finish()
            }
        }
    }

    func saveDigest(_ digest: DailyDigest) {
        mockDigest = digest
    }

    // MARK: - Mock Data Generation

    private static func generateMockSummary(for articles: [Article]) -> String {
        let articleCount = articles.count
        let categories = Set(articles.compactMap { $0.category?.displayName })
        let categoryList = categories.joined(separator: ", ")

        return """
        Today you read \(articleCount) articles covering \(categoryList.isEmpty ? "various topics" : categoryList). \
        The content ranged from breaking news to in-depth analysis, providing a comprehensive view of current events. \
        Key themes included technological advancements, market trends, and global developments. \
        Your reading choices show a diverse interest in staying informed across multiple domains.
        """
    }

    // MARK: - Factory Methods

    static func withSampleData() -> MockFeedService {
        let service = MockFeedService()
        service.mockDigest = DailyDigest(
            id: "mock-digest",
            summary: "This is a sample daily digest summarizing your recent reading activity.",
            sourceArticles: Article.mockArticles,
            generatedAt: Date()
        )
        return service
    }
}
