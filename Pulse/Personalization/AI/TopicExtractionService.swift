import Foundation

/// Protocol for on-device topic extraction.
///
/// Given an article's title (and optional summary), returns 0–5 lowercase
/// kebab-case topic tags. The implementation must guarantee:
///
/// - **No concurrent calls.** llama.cpp's single-thread invariant is
///   enforced by the underlying `LLMService`; callers should still treat
///   `extractTopics(...)` as serial-only.
/// - **No crash on parse failure.** Returns an empty array if the model
///   produces unparseable output.
protocol TopicExtractionService {
    /// `true` when the LLM model is loaded and ready to extract. Drainers
    /// gate on this to avoid forcing a 600 MB model load when no other
    /// premium feature has already paid the cost.
    var isModelAvailable: Bool { get }

    /// Returns 0–5 tags for the article. Throws on LLM error
    /// (`LLMError.memoryPressure`, `.modelNotLoaded`, etc.) — callers in
    /// the drainer treat memory pressure as "stop the batch and try again
    /// later," and other errors as "skip this event, mark processed".
    func extractTopics(title: String, summary: String?) async throws -> [String]
}
