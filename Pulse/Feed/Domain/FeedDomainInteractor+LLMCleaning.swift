import Foundation

extension FeedDomainInteractor {
    nonisolated func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove null characters (LLM sometimes outputs these between tokens)
        cleaned = cleaned.replacingOccurrences(of: "\0", with: "")

        // Remove chat template markers (ChatML + general)
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "<|im_start|>", "<|im_end|>", "</s>", "<s>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = [
            "here's the digest:", "here is the digest:", "digest:", "here's your daily digest:",
            "here is your daily digest:", "sure, here", "sure! here", "here's your news digest:",
            "here are the summaries:", "here is a summary:",
        ]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes where lowercased.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
