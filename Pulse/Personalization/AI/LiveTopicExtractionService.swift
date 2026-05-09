import Foundation

/// Live implementation of `TopicExtractionService` using the on-device
/// `LLMService` (Gemma 3 1B via SwiftLlama).
///
/// Inference config favours determinism — low temperature, low max tokens —
/// because we want consistent tagging across re-extractions and we never
/// need more than ~50 tokens of output (5 tags × ~8 chars each + commas).
final class LiveTopicExtractionService: TopicExtractionService {
    private let llmService: LLMService

    init(llmService: LLMService) {
        self.llmService = llmService
    }

    var isModelAvailable: Bool {
        llmService.isModelLoaded
    }

    func extractTopics(title: String, summary: String?) async throws -> [String] {
        let userPrompt = TopicExtractionPromptBuilder.buildPrompt(
            title: title,
            summary: summary
        )
        let stream = llmService.generateStream(
            prompt: userPrompt,
            systemPrompt: TopicExtractionPromptBuilder.systemPrompt,
            config: .topicExtraction
        )

        var raw = ""
        for try await token in stream {
            raw.append(token)
            // Stop early once we have a likely-complete tag list. The
            // configured stop-sequence already covers `\n\n`, this is a
            // belt-and-suspenders early bail.
            if raw.contains("\n\n") {
                llmService.cancelGeneration()
                break
            }
        }
        return TopicExtractionPromptBuilder.parseTags(from: raw)
    }
}

extension LLMInferenceConfig {
    /// Tight config for tag extraction: deterministic-ish, short output,
    /// stop on blank line.
    static var topicExtraction: LLMInferenceConfig {
        LLMInferenceConfig(
            maxTokens: 80,
            temperature: 0.2,
            topP: 0.9,
            stopSequences: ["\n\n", "</tags>"]
        )
    }
}
