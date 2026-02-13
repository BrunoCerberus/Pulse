import Combine
import Foundation

/// Live implementation of FeedService for AI-powered Daily Digest generation.
///
/// This service manages the AI digest feature, including:
/// - LLM model lifecycle delegation to `LLMService`
/// - Digest generation from news articles with balanced category coverage
/// - In-memory digest caching (today's digest only)
///
/// ## Digest Caching
/// - Caches the most recently generated digest in memory
/// - Returns cached digest if generated today and non-empty
/// - Cache is cleared on app restart
///
/// ## Article Processing
/// Articles are capped using `FeedDigestPromptBuilder.cappedArticles` to:
/// - Prevent context overflow
/// - Ensure balanced category representation
/// - Keep generation times reasonable
final class LiveFeedService: FeedService {
    private let llmService: LLMService
    private var cachedDigest: DailyDigest?

    init(llmService: LLMService? = nil) {
        self.llmService = llmService ?? LiveLLMService()
    }

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        llmService.modelStatusPublisher
    }

    var isModelReady: Bool {
        llmService.isModelLoaded
    }

    func loadModelIfNeeded() async throws {
        guard !isModelReady else { return }
        try await llmService.loadModel()
    }

    func fetchTodaysDigest() -> DailyDigest? {
        guard let cached = cachedDigest,
              Calendar.current.isDateInToday(cached.generatedAt),
              !cached.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return cached
    }

    func generateDigest(from articles: [Article]) -> AsyncThrowingStream<String, Error> {
        // Cap articles to prevent context overflow and ensure reasonable generation time
        let cappedArticles = FeedDigestPromptBuilder.cappedArticles(from: articles)

        let prompt = FeedDigestPromptBuilder.buildPrompt(for: cappedArticles)
        let systemPrompt = FeedDigestPromptBuilder.systemPrompt
        let config = LLMInferenceConfig.dailyDigest

        return llmService.generateStream(
            prompt: prompt,
            systemPrompt: systemPrompt,
            config: config
        )
    }

    func saveDigest(_ digest: DailyDigest) {
        // Only cache digests with non-empty summaries
        guard !digest.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        cachedDigest = digest
    }
}

// MARK: - LLMInferenceConfig Extension

extension LLMInferenceConfig {
    /// Config for daily digest generation
    /// maxTokens set to remaining context after input to prevent overflow while allowing natural completion
    static var dailyDigest: LLMInferenceConfig {
        let inputTokens = (LLMConfiguration.maxArticlesForDigest * LLMConfiguration.estimatedTokensPerArticle)
            + LLMConfiguration.reservedContextTokens
        let availableTokens = LLMConfiguration.contextSize - inputTokens
        // Cap output tokens to prevent repetition loops
        let cappedTokens = min(availableTokens, LLMConfiguration.maxOutputTokens)

        return LLMInferenceConfig(
            maxTokens: cappedTokens,
            temperature: 0.7,
            topP: 0.9,
            stopSequences: ["</digest>", "---"]
        )
    }
}
