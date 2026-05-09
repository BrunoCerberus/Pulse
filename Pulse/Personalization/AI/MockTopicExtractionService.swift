import Foundation

/// In-memory mock of `TopicExtractionService` for unit / preview tests.
///
/// Records every `extractTopics` call into `extractCalls` so tests can assert
/// the drainer iterated the expected events. Errors are injected via
/// `extractionResult = .failure(...)` matching the convention used by
/// `MockSummarizationService`.
final class MockTopicExtractionService: TopicExtractionService, @unchecked Sendable {
    var modelAvailable: Bool = true
    var extractionResult: Result<[String], Error> = .success(["technology", "artificial-intelligence"])
    var extractionDelay: TimeInterval = 0
    /// Convenience hook: per-call result keyed by article title. If a mapping
    /// exists, it overrides `extractionResult` for that call. Lets a single
    /// drainer test exercise heterogeneous tag sets across events.
    var resultsByTitle: [String: Result<[String], Error>] = [:]

    private(set) var extractCalls: [(title: String, summary: String?)] = []

    var isModelAvailable: Bool {
        modelAvailable
    }

    func extractTopics(title: String, summary: String?) async throws -> [String] {
        extractCalls.append((title, summary))
        if extractionDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(extractionDelay * 1_000_000_000))
        }
        if let mapped = resultsByTitle[title] {
            return try mapped.get()
        }
        return try extractionResult.get()
    }
}
