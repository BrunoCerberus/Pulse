import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LLMInferenceConfig Tests")
struct LLMInferenceConfigTests {
    @Test("default config has correct values")
    func defaultConfigHasCorrectValues() {
        let config = LLMInferenceConfig.default
        #expect(config.maxTokens == 1024)
        #expect(config.temperature == 0.7)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</digest>"))
    }

    @Test("dailyDigest config has correct values")
    func dailyDigestConfigHasCorrectValues() {
        let config = LLMInferenceConfig.dailyDigest
        #expect(config.temperature == 0.7)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</digest>"))
        #expect(config.stopSequences.contains("---"))
    }

    @Test("summarization config has correct values")
    func summarizationConfigHasCorrectValues() {
        let config = LLMInferenceConfig.summarization
        #expect(config.maxTokens == 512)
        #expect(config.temperature == 0.5)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</summary>"))
    }
}
