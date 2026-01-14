import Combine
import Foundation

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
    static var dailyDigest: LLMInferenceConfig {
        LLMInferenceConfig(
            maxTokens: 1500,
            temperature: 0.6,
            topP: 0.9,
            stopSequences: ["</digest>", "\n\n\n", "---"]
        )
    }
}
